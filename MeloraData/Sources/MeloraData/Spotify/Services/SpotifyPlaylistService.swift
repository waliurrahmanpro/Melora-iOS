import Foundation

/// Service managing Spotify playlist metadata discovery and track listing.
public final class SpotifyPlaylistService: Sendable {
    private let apiClient: SpotifyAPIClientProtocol

    public init(apiClient: SpotifyAPIClientProtocol) {
        self.apiClient = apiClient
    }

    /// Fetches a paginated slice of playlists owned or followed by the user.
    public func getCurrentUserPlaylists(limit: Int = 20, offset: Int = 0) async throws -> [SpotifyPlaylistDTO] {
        let response: SpotifyPagingDTO<SpotifyPlaylistDTO> = try await apiClient.send(
            endpoint: .userPlaylists(limit: limit, offset: offset)
        )
        return response.items
    }

    /// Fetches detailed metadata for a single playlist by ID.
    public func getPlaylistDetails(playlistId: String) async throws -> SpotifyPlaylistDTO {
        return try await apiClient.send(endpoint: .playlistDetails(playlistId: playlistId))
    }

    /// Fetches paginated tracks contained within a specific Spotify playlist.
    public func getPlaylistTracks(playlistId: String, limit: Int = 100, offset: Int = 0) async throws -> [SpotifyPlaylistTrackItemDTO] {
        let response: SpotifyPagingDTO<SpotifyPlaylistTrackItemDTO> = try await apiClient.send(
            endpoint: .playlistTracks(playlistId: playlistId, limit: limit, offset: offset)
        )
        return response.items
    }
}
