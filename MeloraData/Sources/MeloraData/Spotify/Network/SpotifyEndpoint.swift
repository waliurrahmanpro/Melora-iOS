import Foundation

/// Type-safe definition of Spotify Web API REST endpoints.
public struct SpotifyEndpoint: Sendable {
    public let path: String
    public let method: String
    public let queryItems: [URLQueryItem]

    public init(path: String, method: String = "GET", queryItems: [URLQueryItem] = []) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }

    public static let baseURL = URL(string: "https://api.spotify.com/v1")!

    // MARK: - Current User & Library

    /// GET /v1/me
    public static var currentUserProfile: SpotifyEndpoint {
        SpotifyEndpoint(path: "/me")
    }

    /// GET /v1/me/playlists
    public static func userPlaylists(limit: Int = 20, offset: Int = 0) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/me/playlists", queryItems: [
            URLQueryItem(name: "limit", value: "\(min(max(limit, 1), 50))"),
            URLQueryItem(name: "offset", value: "\(max(offset, 0))")
        ])
    }

    /// GET /v1/me/tracks
    public static func userSavedTracks(limit: Int = 20, offset: Int = 0) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/me/tracks", queryItems: [
            URLQueryItem(name: "limit", value: "\(min(max(limit, 1), 50))"),
            URLQueryItem(name: "offset", value: "\(max(offset, 0))")
        ])
    }

    // MARK: - Playlists

    /// GET /v1/playlists/{playlist_id}
    public static func playlistDetails(playlistId: String) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/playlists/\(playlistId)")
    }

    /// GET /v1/playlists/{playlist_id}/tracks
    public static func playlistTracks(playlistId: String, limit: Int = 100, offset: Int = 0) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/playlists/\(playlistId)/tracks", queryItems: [
            URLQueryItem(name: "limit", value: "\(min(max(limit, 1), 100))"),
            URLQueryItem(name: "offset", value: "\(max(offset, 0))")
        ])
    }

    // MARK: - Search & Catalog

    /// GET /v1/search
    public static func search(query: String, types: [String] = ["track", "artist", "album"], limit: Int = 20, offset: Int = 0) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/search", queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: types.joined(separator: ",")),
            URLQueryItem(name: "limit", value: "\(min(max(limit, 1), 50))"),
            URLQueryItem(name: "offset", value: "\(max(offset, 0))")
        ])
    }

    /// GET /v1/artists/{id}
    public static func artist(id: String) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/artists/\(id)")
    }

    /// GET /v1/albums/{id}
    public static func album(id: String) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/albums/\(id)")
    }

    /// GET /v1/albums/{id}/tracks
    public static func albumTracks(id: String, limit: Int = 50, offset: Int = 0) -> SpotifyEndpoint {
        SpotifyEndpoint(path: "/albums/\(id)/tracks", queryItems: [
            URLQueryItem(name: "limit", value: "\(min(max(limit, 1), 50))"),
            URLQueryItem(name: "offset", value: "\(max(offset, 0))")
        ])
    }
}
