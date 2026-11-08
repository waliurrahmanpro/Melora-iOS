import Foundation

/// Domain model representing a music playlist.
public struct Playlist: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier for the playlist (UUID string).
    public let id: String

    /// User-assigned title of the playlist.
    public let title: String

    /// Optional user description or notes.
    public let description: String?

    /// Local file path or asset name for custom playlist artwork.
    public let artworkPath: String?

    /// Flag indicating if this playlist structure was imported from a connected Spotify account.
    public let isImportedFromSpotify: Bool

    /// Original Spotify playlist ID if imported.
    public let spotifyPlaylistId: String?

    /// Total count of tracks in this playlist.
    public let trackCount: Int

    /// Total duration of all tracks in milliseconds.
    public let totalDurationMs: Int

    /// Timestamp of creation.
    public let createdAt: Date

    /// Timestamp of last modification.
    public let updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        artworkPath: String? = nil,
        isImportedFromSpotify: Bool = false,
        spotifyPlaylistId: String? = nil,
        trackCount: Int = 0,
        totalDurationMs: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.artworkPath = artworkPath
        self.isImportedFromSpotify = isImportedFromSpotify
        self.spotifyPlaylistId = spotifyPlaylistId
        self.trackCount = trackCount
        self.totalDurationMs = totalDurationMs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Formatted total duration (e.g. "45 min", "1 hr 12 min").
    public var durationFormatted: String {
        let totalSeconds = max(0, totalDurationMs / 1000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}

/// Ordered junction entry linking a track to a playlist with an explicit position index.
public struct PlaylistTrack: Identifiable, Hashable, Codable, Sendable {
    public var id: String {
        return "\(playlistId):\(trackId)"
    }

    /// ID of the parent playlist.
    public let playlistId: String

    /// ID of the contained track.
    public let trackId: String

    /// Zero-based position index within the playlist.
    public let position: Int

    /// Timestamp when this track was added to the playlist.
    public let addedAt: Date

    /// Resolved track object if hydrated by repository.
    public let track: Track?

    public init(
        playlistId: String,
        trackId: String,
        position: Int,
        addedAt: Date = Date(),
        track: Track? = nil
    ) {
        self.playlistId = playlistId
        self.trackId = trackId
        self.position = position
        self.addedAt = addedAt
        self.track = track
    }
}
