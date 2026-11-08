import Foundation

/// Item wrapper returned by GET /v1/me/tracks.
public struct SpotifySavedTrackItemDTO: Codable, Sendable, Equatable, Hashable {
    public let addedAt: String?
    public let track: SpotifyTrackDTO

    public init(addedAt: String? = nil, track: SpotifyTrackDTO) {
        self.addedAt = addedAt
        self.track = track
    }

    enum CodingKeys: String, CodingKey {
        case addedAt = "added_at"
        case track
    }
}

/// Service retrieving the authorized user's saved library tracks.
public final class SpotifyLibraryService: Sendable {
    private let apiClient: SpotifyAPIClientProtocol

    public init(apiClient: SpotifyAPIClientProtocol) {
        self.apiClient = apiClient
    }

    /// Fetches the user's saved ("Liked") tracks from their personal Spotify library.
    public func getSavedTracks(limit: Int = 20, offset: Int = 0) async throws -> [SpotifyTrackDTO] {
        let response: SpotifyPagingDTO<SpotifySavedTrackItemDTO> = try await apiClient.send(
            endpoint: .userSavedTracks(limit: limit, offset: offset)
        )
        return response.items.map { $0.track }
    }
}
