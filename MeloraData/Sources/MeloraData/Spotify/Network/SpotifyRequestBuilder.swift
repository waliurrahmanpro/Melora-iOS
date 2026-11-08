import Foundation

/// Builds fully configured URLRequests for the Spotify Web API.
public enum SpotifyRequestBuilder {

    /// Constructs an authorized URLRequest for a given endpoint and access token.
    ///
    /// - Parameters:
    ///   - endpoint: Target Spotify endpoint definition.
    ///   - accessToken: Valid unexpired Bearer token.
    ///   - baseURL: Base URL for the Web API (defaults to https://api.spotify.com/v1).
    /// - Returns: Fully formatted URLRequest ready for execution.
    public static func buildRequest(
        for endpoint: SpotifyEndpoint,
        accessToken: String,
        baseURL: URL = SpotifyEndpoint.baseURL
    ) throws -> URLRequest {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)

        if !endpoint.queryItems.isEmpty {
            urlComponents?.queryItems = endpoint.queryItems
        }

        guard let url = urlComponents?.url else {
            throw SpotifyAPIError.networkError(message: "Failed to construct valid URL for path: \(endpoint.path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }
}
