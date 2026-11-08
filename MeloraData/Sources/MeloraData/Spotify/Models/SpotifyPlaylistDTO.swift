import Foundation

/// Owner representation for a Spotify playlist.
public struct SpotifyPlaylistOwnerDTO: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let displayName: String?

    public init(id: String, displayName: String? = nil) {
        self.id = id
        self.displayName = displayName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

/// Track container item inside a playlist track response.
public struct SpotifyPlaylistTrackItemDTO: Codable, Sendable, Equatable {
    public let addedAt: String?
    public let isLocal: Bool?
    public let track: SpotifyTrackDTO?

    public init(addedAt: String? = nil, isLocal: Bool? = nil, track: SpotifyTrackDTO? = nil) {
        self.addedAt = addedAt
        self.isLocal = isLocal
        self.track = track
    }

    enum CodingKeys: String, CodingKey {
        case addedAt = "added_at"
        case isLocal = "is_local"
        case track
    }
}

/// Playlist representation returned by Spotify Web API endpoints.
public struct SpotifyPlaylistDTO: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let images: [SpotifyImageDTO]?
    public let owner: SpotifyPlaylistOwnerDTO?
    public let tracks: SpotifyPagingDTO<SpotifyPlaylistTrackItemDTO>?
    public let isPublic: Bool?
    public let collaborative: Bool?
    public let snapshotId: String?
    public let uri: String?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        images: [SpotifyImageDTO]? = nil,
        owner: SpotifyPlaylistOwnerDTO? = nil,
        tracks: SpotifyPagingDTO<SpotifyPlaylistTrackItemDTO>? = nil,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        snapshotId: String? = nil,
        uri: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.images = images
        self.owner = owner
        self.tracks = tracks
        self.isPublic = isPublic
        self.collaborative = collaborative
        self.snapshotId = snapshotId
        self.uri = uri
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case images
        case owner
        case tracks
        case isPublic = "public"
        case collaborative
        case snapshotId = "snapshot_id"
        case uri
    }

    /// Primary artwork cover image for the playlist.
    public var primaryArtworkUrl: String? {
        return images?.first?.url
    }

    /// Total number of tracks in the playlist.
    public var totalTracks: Int {
        return tracks?.total ?? 0
    }
}

/// Container object returned by Spotify search endpoint: `GET /v1/search`.
public struct SpotifySearchResponseDTO: Codable, Sendable {
    public let tracks: SpotifyPagingDTO<SpotifyTrackDTO>?
    public let artists: SpotifyPagingDTO<SpotifyArtistDTO>?
    public let albums: SpotifyPagingDTO<SpotifyAlbumDTO>?
    public let playlists: SpotifyPagingDTO<SpotifyPlaylistDTO>?

    public init(
        tracks: SpotifyPagingDTO<SpotifyTrackDTO>? = nil,
        artists: SpotifyPagingDTO<SpotifyArtistDTO>? = nil,
        albums: SpotifyPagingDTO<SpotifyAlbumDTO>? = nil,
        playlists: SpotifyPagingDTO<SpotifyPlaylistDTO>? = nil
    ) {
        self.tracks = tracks
        self.artists = artists
        self.albums = albums
        self.playlists = playlists
    }
}
