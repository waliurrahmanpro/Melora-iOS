import Foundation

/// Specific errors that can occur during audio engine operations.
public enum AudioEngineError: Error, LocalizedError, Equatable, Sendable {
    case audioFileNotFound(path: String)
    case failedToCreatePlayerItem(path: String)
    case playbackItemFailed(message: String)
    case audioSessionActivationFailed(message: String)
    case unsupportedAudioCodec(format: String)
    case queueEmpty
    case invalidSeekPosition(seconds: Double)

    public var errorDescription: String? {
        switch self {
        case .audioFileNotFound(let path):
            return "Audio file not found at: \(path)"
        case .failedToCreatePlayerItem(let path):
            return "Failed to initialize AVPlayerItem for audio file at: \(path)"
        case .playbackItemFailed(let msg):
            return "Playback item failure: \(msg)"
        case .audioSessionActivationFailed(let msg):
            return "Failed to activate audio session: \(msg)"
        case .unsupportedAudioCodec(let fmt):
            return "Unsupported audio format for playback: \(fmt)"
        case .queueEmpty:
            return "Playback queue is empty."
        case .invalidSeekPosition(let sec):
            return "Invalid seek target position: \(sec)s."
        }
    }
}
