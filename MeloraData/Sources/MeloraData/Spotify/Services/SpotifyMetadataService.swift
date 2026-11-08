import Foundation

/// Service retrieving metadata for specific artists and albums.
public final class SpotifyMetadataService: Sendable {
    private let apiClient: SpotifyAPIClientProtocol

    public init(apiClient: SpotifyAPIClientProtocol) {
        self.apiClient = apiClient
    }

    /// Fetches detailed artist metadata including artwork and genres.
    public func getArtist(id: String) async throws -> SpotifyArtistDTO {
        return try await apiClient.send(endpoint: .artist(id: id))
    }

    /// Fetches detailed album metadata including cover art and release year.
    public func getAlbum(id: String) async throws -> SpotifyAlbumDTO {
        return try await apiClient.send(endpoint: .album(id: id))
    }

    /// Fetches tracks contained within a specific album.
    public func getAlbumTracks(id: String, limit: Int = 50, offset: Int = 0) async throws -> [SpotifyTrackDTO] {
        let response: SpotifyPagingDTO<SpotifyTrackDTO> = try await apiClient.send(
            endpoint: .albumTracks(id: id, limit: limit, offset: offset)
        )
        return response.items
    }
}
