import Foundation
import MeloraCore

#if canImport(AVFoundation)
import AVFoundation
#endif

/// Production AVFoundation audio engine conforming to AudioPlayerEngineProtocol.
///
/// Uses AVPlayer, AVPlayerItem, periodic time observers, and AVAudioSession.
public final class AVFoundationAudioEngine: AudioPlayerEngineProtocol, @unchecked Sendable {
    public let configuration: AudioEngineConfiguration
    public let fileStorage: FileStorageProtocol
    public let queueManager: QueueManager

    private let lock = NSLock()
    private var observers: [WeakObserver] = []

    #if canImport(AVFoundation)
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemStatusObserver: NSKeyValueObservation?
    #endif

    private var activeStatus: PlaybackStatus = .idle
    private var activePosition: PlaybackPosition = PlaybackPosition()
    private var activeVolume: Float = 1.0

    public init(
        fileStorage: FileStorageProtocol,
        configuration: AudioEngineConfiguration = .default,
        queueManager: QueueManager = QueueManager()
    ) {
        self.fileStorage = fileStorage
        self.configuration = configuration
        self.queueManager = queueManager

        #if canImport(AVFoundation)
        let newPlayer = AVPlayer()
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer
        setupPeriodicTimeObserver()
        #endif
    }

    deinit {
        stop()
        #if canImport(AVFoundation)
        removeTimeObserver()
        #endif
    }

    // MARK: - AudioPlayerEngineProtocol Properties

    public var currentTrack: Track? {
        return queueManager.currentTrack
    }

    public var status: PlaybackStatus {
        lock.lock()
        defer { lock.unlock() }
        return activeStatus
    }

    public var position: PlaybackPosition {
        lock.lock()
        defer { lock.unlock() }
        return activePosition
    }

    public var volume: Float {
        get {
            lock.lock()
            defer { lock.unlock() }
            return activeVolume
        }
        set {
            let clamped = min(max(newValue, 0.0), 1.0)
            lock.lock()
            self.activeVolume = clamped
            lock.unlock()

            #if canImport(AVFoundation)
            player?.volume = clamped
            #endif
        }
    }

    public var repeatMode: RepeatMode {
        get { queueManager.repeatMode }
        set { queueManager.repeatMode = newValue }
    }

    public var shuffleMode: ShuffleMode {
        get { queueManager.shuffleMode }
        set { queueManager.setShuffleMode(newValue) }
    }

    // MARK: - Observer Management

    public func addObserver(_ observer: AudioPlayerEngineObserver) {
        lock.lock()
        defer { lock.unlock() }
        observers.append(WeakObserver(value: observer))
    }

    public func removeObserver(_ observer: AudioPlayerEngineObserver) {
        lock.lock()
        defer { lock.unlock() }
        observers.removeAll { $0.value == nil || $0.value === observer }
    }

    private func notifyStatusDidChange(_ newStatus: PlaybackStatus) {
        lock.lock()
        self.activeStatus = newStatus
        let currentObservers = observers.compactMap { $0.value }
        lock.unlock()

        for observer in currentObservers {
            observer.audioEngineDidChangeStatus(newStatus)
        }
    }

    private func notifyPositionDidChange(_ newPosition: PlaybackPosition) {
        lock.lock()
        self.activePosition = newPosition
        let currentObservers = observers.compactMap { $0.value }
        lock.unlock()

        for observer in currentObservers {
            observer.audioEngineDidChangePosition(newPosition)
        }
    }

    private func notifyDidFinishPlaying(track: Track) {
        lock.lock()
        let currentObservers = observers.compactMap { $0.value }
        lock.unlock()

        for observer in currentObservers {
            observer.audioEngineDidFinishPlaying(track: track)
        }
    }

    // MARK: - AudioPlayerEngineProtocol Methods

    public func load(track: Track, autoPlay: Bool) async throws {
        notifyStatusDidChange(.loading(trackId: track.id))

        let fileURL = fileStorage.resolveAbsoluteURL(forRelativePath: track.filePath)
        guard fileStorage.fileExists(atRelativePath: track.filePath) else {
            let err = AudioEngineError.audioFileNotFound(path: fileURL.path)
            notifyStatusDidChange(.failed(trackId: track.id, errorDescription: err.localizedDescription))
            throw err
        }

        #if canImport(AVFoundation)
        let asset = AVURLAsset(url: fileURL)
        let playerItem = AVPlayerItem(asset: asset)

        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player?.replaceCurrentItem(with: playerItem)

        let durationSeconds = track.durationSeconds
        notifyPositionDidChange(PlaybackPosition(currentTimeSeconds: 0.0, durationSeconds: durationSeconds))

        if autoPlay {
            play()
        } else {
            notifyStatusDidChange(.paused(trackId: track.id))
        }
        #else
        // Host without AVFoundation runtime
        notifyPositionDidChange(PlaybackPosition(currentTimeSeconds: 0.0, durationSeconds: track.durationSeconds))
        if autoPlay {
            notifyStatusDidChange(.playing(trackId: track.id))
        } else {
            notifyStatusDidChange(.paused(trackId: track.id))
        }
        #endif
    }

    public func play() {
        guard let current = currentTrack else { return }

        #if canImport(AVFoundation)
        player?.play()
        #endif

        notifyStatusDidChange(.playing(trackId: current.id))
    }

    public func pause() {
        guard let current = currentTrack else { return }

        #if canImport(AVFoundation)
        player?.pause()
        #endif

        notifyStatusDidChange(.paused(trackId: current.id))
    }

    public func togglePlayPause() {
        if status.isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func stop() {
        #if canImport(AVFoundation)
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        #endif

        notifyPositionDidChange(PlaybackPosition(currentTimeSeconds: 0.0, durationSeconds: 0.0))
        notifyStatusDidChange(.stopped)
    }

    public func seek(toSeconds seconds: Double) async {
        guard let current = currentTrack else { return }
        let clamped = min(max(seconds, 0.0), current.durationSeconds)

        #if canImport(AVFoundation)
        let targetTime = CMTime(seconds: clamped, preferredTimescale: 1000)
        await player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        #endif

        notifyPositionDidChange(PlaybackPosition(currentTimeSeconds: clamped, durationSeconds: current.durationSeconds))
    }

    public func setQueue(tracks: [Track], startIndex: Int) async throws {
        queueManager.setQueue(tracks: tracks, startIndex: startIndex)
        if let first = queueManager.currentTrack {
            try await load(track: first, autoPlay: true)
        } else {
            stop()
        }
    }

    public func skipToNext() async {
        if let next = queueManager.nextTrack() {
            try? await load(track: next, autoPlay: true)
        } else {
            stop()
        }
    }

    public func skipToPrevious() async {
        let (track, restart) = queueManager.previousTrack(currentPositionSeconds: position.currentTimeSeconds)
        if restart {
            await seek(toSeconds: 0.0)
            play()
        } else if let prev = track {
            try? await load(track: prev, autoPlay: true)
        }
    }

    // MARK: - Internal Notifications & Observers

    #if canImport(AVFoundation)
    private func setupPeriodicTimeObserver() {
        let interval = CMTime(seconds: configuration.timeObserverInterval, preferredTimescale: 1000)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let current = self.currentTrack else { return }
            let currentTime = CMTimeGetSeconds(time)
            if currentTime.isFinite && currentTime >= 0 {
                self.notifyPositionDidChange(PlaybackPosition(
                    currentTimeSeconds: currentTime,
                    durationSeconds: current.durationSeconds
                ))
            }
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            self.timeObserverToken = nil
        }
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        guard let current = currentTrack else { return }
        notifyDidFinishPlaying(track: current)

        if configuration.autoAdvanceOnCompletion {
            Task {
                await self.skipToNext()
            }
        }
    }
    #endif
}

private struct WeakObserver {
    weak var value: AudioPlayerEngineObserver?
}
