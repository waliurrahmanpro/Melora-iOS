import Foundation

/// Service performing catalog searches across tracks, artists, and albums.
public final class SpotifySearchService: Sendable {
    private let apiClient: SpotifyAPIClientProtocol

    public init(apiClient: SpotifyAPIClientProtocol) {
        self.apiClient = apiClient
    }

    /// Searches Spotify catalog for tracks, artists, and albums for metadata enrichment.
    public func searchCatalog(
        query: String,
        types: [String] = ["track", "artist", "album"],
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> SpotifySearchResponseDTO {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return SpotifySearchResponseDTO()
        }

        return try await apiClient.send(
            endpoint: .search(query: trimmed, types: types, limit: limit, offset: offset)
        )
    }
}
