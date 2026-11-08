import Foundation

/// Core domain entity representing a local audio file within the user's library.
///
/// Every track corresponds to a local file stored securely in the app's sandboxed storage.
/// Tracks may optionally link to a Spotify Track ID for metadata discovery and artwork.
public struct Track: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier for the track (UUID string).
    public let id: String

    /// Track title extracted from metadata or file tags.
    public let title: String

    /// Primary artist name.
    public let artistName: String

    /// Album title if available.
    public let albumTitle: String?

    /// Duration of the audio file in milliseconds.
    public let durationMs: Int

    /// Relative file path inside the app's sandboxed storage (e.g., "Tracks/abc-123.flac").
    public let filePath: String

    /// File size on disk in bytes.
    public let fileSizeBytes: Int64

    /// Audio codec and container format.
    public let audioFormat: AudioFormat

    /// Audio bitrate in bits per second (e.g. 320000 for 320kbps MP3), if known.
    public let bitrate: Int?

    /// Audio sample rate in Hz (e.g. 44100, 96000), if known.
    public let sampleRate: Int?

    /// Number of audio channels (e.g. 2 for stereo, 1 for mono).
    public let channels: Int

    /// Optional Spotify track ID linked for metadata and album art discovery.
    /// Note: Spotify integration is strictly used for metadata discovery, never for streaming playback.
    public let spotifyId: String?

    /// Local file path to cached artwork thumbnail.
    public let artworkPath: String?

    /// SHA-256 hash of the audio file content used for duplicate detection.
    public let fileHash: String?

    /// Timestamp when this track was added to the local library.
    public let createdAt: Date

    /// Timestamp when this track metadata was last updated.
    public let updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        artistName: String,
        albumTitle: String? = nil,
        durationMs: Int,
        filePath: String,
        fileSizeBytes: Int64,
        audioFormat: AudioFormat,
        bitrate: Int? = nil,
        sampleRate: Int? = nil,
        channels: Int = 2,
        spotifyId: String? = nil,
        artworkPath: String? = nil,
        fileHash: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.durationMs = durationMs
        self.filePath = filePath
        self.fileSizeBytes = fileSizeBytes
        self.audioFormat = audioFormat
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.channels = channels
        self.spotifyId = spotifyId
        self.artworkPath = artworkPath
        self.fileHash = fileHash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Human-readable duration in "m:ss" or "h:mm:ss" format.
    public var durationFormatted: String {
        let totalSeconds = max(0, durationMs / 1000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Human-readable file size string (e.g. "8.4 MB").
    public var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSizeBytes)
    }

    /// Duration in fractional seconds for AVFoundation players.
    public var durationSeconds: Double {
        return Double(durationMs) / 1000.0
    }
}
