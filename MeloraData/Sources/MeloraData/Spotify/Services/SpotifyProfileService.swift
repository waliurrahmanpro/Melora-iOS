import Foundation

/// Service retrieving authenticated user profile information.
public final class SpotifyProfileService: Sendable {
    private let apiClient: SpotifyAPIClientProtocol

    public init(apiClient: SpotifyAPIClientProtocol) {
        self.apiClient = apiClient
    }

    /// Fetches the profile of the currently authorized Spotify user.
    public func getCurrentUserProfile() async throws -> SpotifyUserProfile {
        return try await apiClient.send(endpoint: .currentUserProfile)
    }
}
