import Foundation

/// Track representation returned by Spotify Web API endpoints.
///
/// NOTE: Spotify Web API tracks represent catalog metadata. Melora does not stream
/// copyrighted audio from Spotify; audio playback is handled strictly by user-owned local files.
public struct SpotifyTrackDTO: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let artists: [SpotifyArtistDTO]?
    public let album: SpotifyAlbumDTO?
    public let durationMs: Int
    public let explicit: Bool?
    public let popularity: Int?
    public let discNumber: Int?
    public let trackNumber: Int?
    public let uri: String?
    public let isPlayable: Bool?
    public let isLocal: Bool?

    /// Deprecated by Spotify and nullable. Melora does NOT rely on preview_url for playback.
    public let previewUrl: String?

    public init(
        id: String,
        name: String,
        artists: [SpotifyArtistDTO]? = nil,
        album: SpotifyAlbumDTO? = nil,
        durationMs: Int,
        explicit: Bool? = nil,
        popularity: Int? = nil,
        discNumber: Int? = nil,
        trackNumber: Int? = nil,
        uri: String? = nil,
        isPlayable: Bool? = nil,
        isLocal: Bool? = nil,
        previewUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.artists = artists
        self.album = album
        self.durationMs = durationMs
        self.explicit = explicit
        self.popularity = popularity
        self.discNumber = discNumber
        self.trackNumber = trackNumber
        self.uri = uri
        self.isPlayable = isPlayable
        self.isLocal = isLocal
        self.previewUrl = previewUrl
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case artists
        case album
        case durationMs = "duration_ms"
        case explicit
        case popularity
        case discNumber = "disc_number"
        case trackNumber = "track_number"
        case uri
        case isPlayable = "is_playable"
        case isLocal = "is_local"
        case previewUrl = "preview_url"
    }

    /// Primary artist name.
    public var primaryArtistName: String {
        return artists?.first?.name ?? "Unknown Artist"
    }

    /// Album artwork URL if available.
    public var artworkUrl: String? {
        return album?.primaryArtworkUrl
    }
}
