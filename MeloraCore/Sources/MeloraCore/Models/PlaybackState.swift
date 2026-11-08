import Foundation

/// Represents the active state of the Melora audio playback engine.
public enum PlaybackStatus: Equatable, Sendable {
    case idle
    case loading(trackId: String)
    case playing(trackId: String)
    case paused(trackId: String)
    case stopped
    case failed(trackId: String?, errorDescription: String)

    public var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }

    public var activeTrackId: String? {
        switch self {
        case .loading(let id), .playing(let id), .paused(let id):
            return id
        case .failed(let id, _):
            return id
        case .idle, .stopped:
            return nil
        }
    }
}

/// Loop/repeat mode for playback queue sequencing.
public enum RepeatMode: String, Codable, CaseIterable, Sendable {
    case off = "off"
    case all = "all"
    case one = "one"
}

/// Shuffle state for playback queue ordering.
public enum ShuffleMode: String, Codable, CaseIterable, Sendable {
    case off = "off"
    case on = "on"
}

/// Precise playback timeline coordinates.
public struct PlaybackPosition: Equatable, Sendable {
    public let currentTimeSeconds: Double
    public let durationSeconds: Double

    public var progress: Double {
        guard durationSeconds > 0 else { return 0.0 }
        return min(max(currentTimeSeconds / durationSeconds, 0.0), 1.0)
    }

    public var remainingSeconds: Double {
        return max(durationSeconds - currentTimeSeconds, 0.0)
    }

    public init(currentTimeSeconds: Double = 0.0, durationSeconds: Double = 0.0) {
        self.currentTimeSeconds = currentTimeSeconds
        self.durationSeconds = durationSeconds
    }
}
