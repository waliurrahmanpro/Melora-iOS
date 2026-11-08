import Foundation

/// Supported native audio container and codec formats for local playback in Melora.
public enum AudioFormat: String, Codable, CaseIterable, Sendable {
    case mp3 = "mp3"
    case m4a = "m4a"
    case aac = "aac"
    case flac = "flac"
    case alac = "alac"
    case wav = "wav"
    case aiff = "aiff"

    /// Standard MIME type for the audio format.
    public var mimeType: String {
        switch self {
        case .mp3:
            return "audio/mpeg"
        case .m4a, .alac:
            return "audio/mp4"
        case .aac:
            return "audio/aac"
        case .flac:
            return "audio/flac"
        case .wav:
            return "audio/wav"
        case .aiff:
            return "audio/aiff"
        }
    }

    /// Primary file extension associated with this audio format.
    public var fileExtension: String {
        return self.rawValue
    }

    /// Indicates whether this format provides lossless audio reproduction.
    public var isLossless: Bool {
        switch self {
        case .flac, .alac, .wav, .aiff:
            return true
        case .mp3, .m4a, .aac:
            return false
        }
    }

    /// Initializes an AudioFormat from a filename or path extension.
    public init?(fileExtension: String) {
        let cleaned = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        switch cleaned {
        case "mp3":
            self = .mp3
        case "m4a":
            self = .m4a
        case "aac":
            self = .aac
        case "flac":
            self = .flac
        case "alac":
            self = .alac
        case "wav", "wave":
            self = .wav
        case "aiff", "aif":
            self = .aiff
        default:
            return nil
        }
    }
}
