import Foundation
import MeloraCore
import MeloraData
import MeloraAudio

#if canImport(Observation)
import Observation
#endif

/// Master ViewModel for playback state, timeline observation, and queue manipulation.
@Observable
public final class PlayerViewModel: AudioPlayerEngineObserver, @unchecked Sendable {
    public let coordinator: AudioPlaybackCoordinator

    public var currentTrack: Track?
    public var status: PlaybackStatus = .idle
    public var position: PlaybackPosition = PlaybackPosition()
    public var repeatMode: RepeatMode = .off
    public var shuffleMode: ShuffleMode = .off
    public var queue: [Track] = []

    public var isNowPlayingPresented: Bool = false
    public var isQueuePresented: Bool = false
    public var isLyricsPresented: Bool = false
    public var isFavorite: Bool = false

    public init(coordinator: AudioPlaybackCoordinator) {
        self.coordinator = coordinator
        self.currentTrack = coordinator.audioEngine.currentTrack
        self.status = coordinator.audioEngine.status
        self.position = coordinator.audioEngine.position
        self.repeatMode = coordinator.audioEngine.repeatMode
        self.shuffleMode = coordinator.audioEngine.shuffleMode

        coordinator.audioEngine.addObserver(self)
    }

    deinit {
        coordinator.audioEngine.removeObserver(self)
    }

    // MARK: - Playback Control Actions

    public func playTrack(_ track: Track, queue: [Track] = []) {
        Task { @MainActor in
            let queueToPlay = queue.isEmpty ? [track] : queue
            let index = queueToPlay.firstIndex(where: { $0.id == track.id }) ?? 0
            try? await self.coordinator.playQueue(tracks: queueToPlay, startIndex: index)
        }
    }

    public func togglePlayPause() {
        coordinator.togglePlayPause()
    }

    public func skipToNext() {
        Task { @MainActor in
            await self.coordinator.skipToNext()
        }
    }

    public func skipToPrevious() {
        Task { @MainActor in
            await self.coordinator.skipToPrevious()
        }
    }

    public func seek(toSeconds seconds: Double) {
        Task { @MainActor in
            await self.coordinator.seek(toSeconds: seconds)
        }
    }

    public func toggleShuffle() {
        let newMode: ShuffleMode = shuffleMode == .on ? .off : .on
        coordinator.audioEngine.shuffleMode = newMode
        self.shuffleMode = newMode
        syncQueue()
    }

    public func cycleRepeatMode() {
        let nextMode: RepeatMode
        switch repeatMode {
        case .off: nextMode = .all
        case .all: nextMode = .one
        case .one: nextMode = .off
        }
        coordinator.audioEngine.repeatMode = nextMode
        self.repeatMode = nextMode
    }

    public func toggleFavorite() {
        self.isFavorite.toggle()
    }

    public func syncQueue() {
        if let engine = coordinator.audioEngine as? AVFoundationAudioEngine {
            self.queue = engine.queueManager.queue
        }
    }

    // MARK: - AudioPlayerEngineObserver

    public func audioEngineDidChangeStatus(_ status: PlaybackStatus) {
        Task { @MainActor in
            self.status = status
            self.currentTrack = self.coordinator.audioEngine.currentTrack
            self.syncQueue()
        }
    }

    public func audioEngineDidChangePosition(_ position: PlaybackPosition) {
        Task { @MainActor in
            self.position = position
        }
    }

    public func audioEngineDidFinishPlaying(track: Track) {
        Task { @MainActor in
            self.syncQueue()
        }
    }
}
