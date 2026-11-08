import Foundation

/// Summary entity representing a user's Spotify playlist for metadata exploration and importing.
public struct SpotifyPlaylistMetadata: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let artworkUrl: String?
    public let totalTracks: Int
    public let ownerName: String?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        artworkUrl: String? = nil,
        totalTracks: Int = 0,
        ownerName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.artworkUrl = artworkUrl
        self.totalTracks = totalTracks
        self.ownerName = ownerName
    }
}

/// Metadata-only entity representing a track from Spotify Web API.
public struct SpotifyTrackMetadata: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let albumTitle: String?
    public let durationMs: Int
    public let artworkUrl: String?
    public let isExplicit: Bool

    public init(
        id: String,
        title: String,
        artistName: String,
        albumTitle: String? = nil,
        durationMs: Int = 0,
        artworkUrl: String? = nil,
        isExplicit: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.durationMs = durationMs
        self.artworkUrl = artworkUrl
        self.isExplicit = isExplicit
    }
}

/// Abstract contract for Spotify Web API integration.
///
/// Designed strictly in compliance with Spotify Developer Terms:
/// Provides authorized OAuth authentication, playlist metadata, saved tracks where permitted,
/// artists, albums, and music discovery. Melora never extracts or downloads copyrighted audio from Spotify.
public protocol SpotifyServiceProtocol: AnyObject, Sendable {
    /// Indicates whether a valid OAuth token session is currently active.
    var isAuthenticated: Bool { get }

    /// Initiates the OAuth 2.0 PKCE authentication flow.
    func authenticate() async throws

    /// Revokes active session tokens and logs out.
    func disconnect() async throws

    /// Fetches the user's public and private playlists.
    func getUserPlaylists(limit: Int, offset: Int) async throws -> [SpotifyPlaylistMetadata]

    /// Fetches metadata for tracks in a specific Spotify playlist.
    func getPlaylistTracks(playlistId: String, limit: Int, offset: Int) async throws -> [SpotifyTrackMetadata]

    /// Searches Spotify catalog for tracks, artists, and albums for metadata enrichment.
    func searchCatalog(query: String, limit: Int) async throws -> [SpotifyTrackMetadata]

    /// Retrieves detailed artist metadata including artwork URLs.
    func getArtist(spotifyId: String) async throws -> Artist?

    /// Retrieves detailed album metadata including cover art.
    func getAlbum(spotifyId: String) async throws -> Album?

    /// Generates the OAuth 2.0 PKCE authorization URL.
    func getAuthorizationURL() -> URL?

    /// Processes an incoming OAuth callback URL and exchanges the authorization code for tokens.
    func handleRedirectURL(_ url: URL) async throws -> Bool
}

extension SpotifyServiceProtocol {
    public func getAuthorizationURL() -> URL? { nil }
    public func handleRedirectURL(_ url: URL) async throws -> Bool { false }
}
