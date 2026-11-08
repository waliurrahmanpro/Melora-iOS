import Foundation

/// Contract for executing requests against the Spotify Web API.
public protocol SpotifyAPIClientProtocol: Sendable {
    func send<T: Decodable & Sendable>(endpoint: SpotifyEndpoint) async throws -> T
}

/// Client managing authenticated REST communication with the Spotify Web API.
public final class SpotifyAPIClient: SpotifyAPIClientProtocol, @unchecked Sendable {
    private let tokenManager: TokenManager
    private let rateLimiter: SpotifyRateLimiter
    private let urlSession: URLSession
    private let baseURL: URL

    public init(
        tokenManager: TokenManager,
        rateLimiter: SpotifyRateLimiter = SpotifyRateLimiter(),
        urlSession: URLSession = .shared,
        baseURL: URL = SpotifyEndpoint.baseURL
    ) {
        self.tokenManager = tokenManager
        self.rateLimiter = rateLimiter
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    /// Executes an authorized endpoint request, automatically refreshing tokens and respecting rate limits.
    public func send<T: Decodable & Sendable>(endpoint: SpotifyEndpoint) async throws -> T {
        // 1. Wait if currently under a rate-limiting cooldown
        await rateLimiter.waitForCooldownIfNeeded()

        // 2. Obtain valid Bearer access token
        let token = try await tokenManager.getValidAccessToken()

        // 3. Build URLRequest
        let request = try SpotifyRequestBuilder.buildRequest(
            for: endpoint,
            accessToken: token,
            baseURL: baseURL
        )

        // 4. Perform network call
        let (data, response) = try await urlSession.data(for: request)

        // 5. Inspect for rate limiting (429)
        if let httpResponse = response as? HTTPURLResponse {
            _ = await rateLimiter.inspectResponse(httpResponse)

            // If 401 Unauthorized, attempt a single token refresh and retry
            if httpResponse.statusCode == 401 {
                let freshToken = try await tokenManager.refreshAccessToken()
                let retryRequest = try SpotifyRequestBuilder.buildRequest(
                    for: endpoint,
                    accessToken: freshToken,
                    baseURL: baseURL
                )
                let (retryData, retryResponse) = try await urlSession.data(for: retryRequest)
                return try SpotifyResponseHandler.handleResponse(data: retryData, response: retryResponse)
            }
        }

        // 6. Handle response and decode payload
        return try SpotifyResponseHandler.handleResponse(data: data, response: response)
    }
}
