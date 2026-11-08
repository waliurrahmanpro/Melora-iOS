import Foundation
import MeloraCore

/// Thread-safe in-memory mock implementing AudioPlayerEngineProtocol for portable testing.
public final class MockAudioPlayerEngine: AudioPlayerEngineProtocol, @unchecked Sendable {
    private let lock = NSLock()

    public var queueManager: QueueManager = QueueManager()
    public var observers: [AudioPlayerEngineObserver] = []

    public var activeTrack: Track?
    public var activeStatus: PlaybackStatus = .idle
    public var activePosition: PlaybackPosition = PlaybackPosition()
    public var activeVolume: Float = 1.0

    // Spy tracking
    public var playCallCount = 0
    public var pauseCallCount = 0
    public var stopCallCount = 0
    public var seekCallCount = 0
    public var lastSeekTarget: Double?
    public var loadedTracks: [Track] = []

    public init() {}

    public var currentTrack: Track? {
        lock.lock()
        defer { lock.unlock() }
        return activeTrack
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
            lock.lock()
            defer { lock.unlock() }
            activeVolume = newValue
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

    public func addObserver(_ observer: AudioPlayerEngineObserver) {
        lock.lock()
        defer { lock.unlock() }
        observers.append(observer)
    }

    public func removeObserver(_ observer: AudioPlayerEngineObserver) {
        lock.lock()
        defer { lock.unlock() }
        observers.removeAll { $0 === observer }
    }

    public func load(track: Track, autoPlay: Bool) async throws {
        lock.lock()
        activeTrack = track
        loadedTracks.append(track)
        activePosition = PlaybackPosition(currentTimeSeconds: 0, durationSeconds: track.durationSeconds)
        activeStatus = autoPlay ? .playing(trackId: track.id) : .paused(trackId: track.id)
        let obs = observers
        let stat = activeStatus
        let pos = activePosition
        lock.unlock()

        for o in obs {
            o.audioEngineDidChangeStatus(stat)
            o.audioEngineDidChangePosition(pos)
        }
    }

    public func play() {
        lock.lock()
        playCallCount += 1
        guard let track = activeTrack else {
            lock.unlock()
            return
        }
        activeStatus = .playing(trackId: track.id)
        let obs = observers
        let stat = activeStatus
        lock.unlock()

        for o in obs {
            o.audioEngineDidChangeStatus(stat)
        }
    }

    public func pause() {
        lock.lock()
        pauseCallCount += 1
        guard let track = activeTrack else {
            lock.unlock()
            return
        }
        activeStatus = .paused(trackId: track.id)
        let obs = observers
        let stat = activeStatus
        lock.unlock()

        for o in obs {
            o.audioEngineDidChangeStatus(stat)
        }
    }

    public func togglePlayPause() {
        if status.isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func stop() {
        lock.lock()
        stopCallCount += 1
        activeStatus = .stopped
        activePosition = PlaybackPosition(currentTimeSeconds: 0, durationSeconds: 0)
        let obs = observers
        let stat = activeStatus
        let pos = activePosition
        lock.unlock()

        for o in obs {
            o.audioEngineDidChangeStatus(stat)
            o.audioEngineDidChangePosition(pos)
        }
    }

    public func seek(toSeconds seconds: Double) async {
        lock.lock()
        seekCallCount += 1
        lastSeekTarget = seconds
        guard let track = activeTrack else {
            lock.unlock()
            return
        }
        activePosition = PlaybackPosition(currentTimeSeconds: seconds, durationSeconds: track.durationSeconds)
        let obs = observers
        let pos = activePosition
        lock.unlock()

        for o in obs {
            o.audioEngineDidChangePosition(pos)
        }
    }

    public func setQueue(tracks: [Track], startIndex: Int) async throws {
        queueManager.setQueue(tracks: tracks, startIndex: startIndex)
        if let current = queueManager.currentTrack {
            try await load(track: current, autoPlay: true)
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
            await seek(toSeconds: 0)
            play()
        } else if let prev = track {
            try? await load(track: prev, autoPlay: true)
        }
    }

    /// Simulates reaching the end of the currently playing track.
    public func simulateTrackCompletion() async {
        lock.lock()
        guard let current = activeTrack else {
            lock.unlock()
            return
        }
        let obs = observers
        lock.unlock()

        for o in obs {
            o.audioEngineDidFinishPlaying(track: current)
        }

        await skipToNext()
    }
}
