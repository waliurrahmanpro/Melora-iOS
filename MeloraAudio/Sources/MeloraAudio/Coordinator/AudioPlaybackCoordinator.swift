import Foundation
import MeloraCore

/// Master coordinator binding the audio engine, queue, session interruptions, lock screen controls, and history logging.
public final class AudioPlaybackCoordinator: AudioPlayerEngineObserver, AudioSessionManagerDelegate, RemoteCommandHandlerDelegate, @unchecked Sendable {
    public let audioEngine: AudioPlayerEngineProtocol
    public let audioSessionManager: AudioSessionManager
    public let nowPlayingCoordinator: NowPlayingInfoCoordinator
    public let remoteCommandHandler: RemoteCommandHandler
    public let historyRepository: PlaybackHistoryRepositoryProtocol?

    public let configuration: AudioEngineConfiguration

    private let lock = NSLock()
    private var sessionAccumulatedSeconds: Double = 0.0
    private var sessionLastPlayTimestamp: Date?
    private var wasPlayingBeforeInterruption = false

    public init(
        audioEngine: AudioPlayerEngineProtocol,
        audioSessionManager: AudioSessionManager = AudioSessionManager(),
        nowPlayingCoordinator: NowPlayingInfoCoordinator = NowPlayingInfoCoordinator(),
        remoteCommandHandler: RemoteCommandHandler = RemoteCommandHandler(),
        historyRepository: PlaybackHistoryRepositoryProtocol? = nil,
        configuration: AudioEngineConfiguration = .default
    ) {
        self.audioEngine = audioEngine
        self.audioSessionManager = audioSessionManager
        self.nowPlayingCoordinator = nowPlayingCoordinator
        self.remoteCommandHandler = remoteCommandHandler
        self.historyRepository = historyRepository
        self.configuration = configuration

        audioEngine.addObserver(self)
        audioSessionManager.delegate = self
        remoteCommandHandler.delegate = self
    }

    deinit {
        audioEngine.removeObserver(self)
    }

    // MARK: - Playback Control API

    public func playQueue(tracks: [Track], startIndex: Int = 0) async throws {
        try audioSessionManager.activateSession()
        try await audioEngine.setQueue(tracks: tracks, startIndex: startIndex)
    }

    public func play() {
        try? audioSessionManager.activateSession()
        audioEngine.play()
    }

    public func pause() {
        audioEngine.pause()
    }

    public func togglePlayPause() {
        audioEngine.togglePlayPause()
    }

    public func stop() {
        finalizeHistoryLoggingIfNeeded()
        audioEngine.stop()
        nowPlayingCoordinator.clearNowPlaying()
        audioSessionManager.deactivateSession()
    }

    public func skipToNext() async {
        finalizeHistoryLoggingIfNeeded()
        await audioEngine.skipToNext()
    }

    public func skipToPrevious() async {
        finalizeHistoryLoggingIfNeeded()
        await audioEngine.skipToPrevious()
    }

    public func seek(toSeconds seconds: Double) async {
        await audioEngine.seek(toSeconds: seconds)
    }

    // MARK: - AudioPlayerEngineObserver

    public func audioEngineDidChangeStatus(_ status: PlaybackStatus) {
        lock.lock()
        switch status {
        case .playing:
            sessionLastPlayTimestamp = Date()
        case .paused, .stopped, .failed:
            if let last = sessionLastPlayTimestamp {
                sessionAccumulatedSeconds += Date().timeIntervalSince(last)
                sessionLastPlayTimestamp = nil
            }
        case .idle, .loading:
            break
        }
        lock.unlock()

        if let current = audioEngine.currentTrack {
            nowPlayingCoordinator.updatePlaybackState(
                position: audioEngine.position,
                isPlaying: status.isPlaying
            )
        }
    }

    public func audioEngineDidChangePosition(_ position: PlaybackPosition) {
        nowPlayingCoordinator.updatePlaybackState(
            position: position,
            isPlaying: audioEngine.status.isPlaying
        )
    }

    public func audioEngineDidFinishPlaying(track: Track) {
        finalizeHistoryLoggingIfNeeded(for: track, completedTrack: true)
    }

    // MARK: - AudioSessionManagerDelegate

    public func audioSessionInterruptionBegan() {
        lock.lock()
        wasPlayingBeforeInterruption = audioEngine.status.isPlaying
        lock.unlock()

        audioEngine.pause()
    }

    public func audioSessionInterruptionEnded(shouldResume: Bool) {
        lock.lock()
        let shouldRestart = wasPlayingBeforeInterruption && shouldResume
        wasPlayingBeforeInterruption = false
        lock.unlock()

        if shouldRestart {
            play()
        }
    }

    public func audioSessionHeadphonesDisconnected() {
        if configuration.pauseOnHeadphoneDisconnect && audioEngine.status.isPlaying {
            audioEngine.pause()
        }
    }

    // MARK: - RemoteCommandHandlerDelegate

    public func remoteCommandPlay() {
        play()
    }

    public func remoteCommandPause() {
        pause()
    }

    public func remoteCommandTogglePlayPause() {
        togglePlayPause()
    }

    public func remoteCommandNextTrack() {
        Task {
            await skipToNext()
        }
    }

    public func remoteCommandPreviousTrack() {
        Task {
            await skipToPrevious()
        }
    }

    public func remoteCommandSeek(toSeconds seconds: Double) {
        Task {
            await seek(toSeconds: seconds)
        }
    }

    // MARK: - History Logging Helper

    private func finalizeHistoryLoggingIfNeeded(for track: Track? = nil, completedTrack: Bool = false) {
        lock.lock()
        if let last = sessionLastPlayTimestamp {
            sessionAccumulatedSeconds += Date().timeIntervalSince(last)
            sessionLastPlayTimestamp = nil
        }
        let totalPlaySeconds = sessionAccumulatedSeconds
        sessionAccumulatedSeconds = 0.0
        lock.unlock()

        guard let targetTrack = track ?? audioEngine.currentTrack else { return }

        let durationSeconds = targetTrack.durationSeconds
        guard durationSeconds > 0 else { return }

        let completion = min(totalPlaySeconds / durationSeconds, 1.0)
        let meetsThreshold = completion >= configuration.historyCompletionThreshold ||
                             totalPlaySeconds >= Double(configuration.historyMinimumSeconds) ||
                             completedTrack

        if meetsThreshold {
            let entry = PlaybackHistory(
                trackId: targetTrack.id,
                track: targetTrack,
                playedAt: Date(),
                durationPlayedMs: Int(totalPlaySeconds * 1000.0),
                completionPercentage: completion
            )
            try? historyRepository?.record(historyEntry: entry)
        }
    }
}
