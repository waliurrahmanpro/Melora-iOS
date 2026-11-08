import Foundation

/// Errors related to OAuth token management and renewal.
public enum TokenError: Error, LocalizedError, Equatable, Sendable {
    case notAuthenticated
    case missingRefreshToken
    case refreshFailed(String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "No Spotify authentication session found. Please log in."
        case .missingRefreshToken:
            return "No refresh token available to renew session. Re-authentication required."
        case .refreshFailed(let msg):
            return "Failed to refresh Spotify access token: \(msg)"
        case .invalidResponse:
            return "Invalid token response received from Spotify server."
        }
    }
}

/// Actor managing token lifecycles, proactive expiration renewal, and synchronization.
public actor TokenManager {
    private let configuration: SpotifyAuthorizationConfiguration
    private let tokenStorage: SecureTokenStorageProtocol
    private let urlSession: URLSession
    private var refreshTask: Task<String, Error>?

    public init(
        configuration: SpotifyAuthorizationConfiguration,
        tokenStorage: SecureTokenStorageProtocol,
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.tokenStorage = tokenStorage
        self.urlSession = urlSession
    }

    /// Checks if a valid session exists.
    public var isAuthenticated: Bool {
        return tokenStorage.getAccessToken() != nil
    }

    /// Retrieves an unexpired access token, automatically refreshing if needed.
    public func getValidAccessToken() async throws -> String {
        // If existing token is still valid, return it immediately
        if !tokenStorage.isTokenExpired(bufferSeconds: 60), let token = tokenStorage.getAccessToken() {
            return token
        }

        // If a refresh is already underway, await its result (prevents concurrent duplicate refresh requests)
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        // Launch single refresh task
        let task = Task<String, Error> {
            defer { self.refreshTask = nil }
            return try await self.refreshAccessToken()
        }
        self.refreshTask = task
        return try await task.value
    }

    /// Stores newly received tokens from authorization code exchange.
    public func storeTokens(_ tokenResponse: SpotifyTokenResponse) throws {
        try tokenStorage.saveTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: tokenResponse.expiresIn
        )
    }

    /// Clears all stored tokens and resets session.
    public func clearTokens() throws {
        try tokenStorage.clearTokens()
    }

    /// Exchanges an authorization code and PKCE code verifier for tokens.
    public func exchangeCodeForTokens(code: String, codeVerifier: String) async throws -> SpotifyTokenResponse {
        var request = URLRequest(url: configuration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": configuration.redirectUri.absoluteString,
            "client_id": configuration.clientId,
            "code_verifier": codeVerifier
        ]

        request.httpBody = formatFormData(params)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMsg = parseErrorBody(data: data, statusCode: httpResponse.statusCode)
            throw TokenError.refreshFailed(errorMsg)
        }

        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(SpotifyTokenResponse.self, from: data)
        try storeTokens(tokenResponse)
        return tokenResponse
    }

    /// Refreshes the access token using the stored refresh token.
    @discardableResult
    public func refreshAccessToken() async throws -> String {
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            throw TokenError.missingRefreshToken
        }

        var request = URLRequest(url: configuration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": configuration.clientId
        ]

        request.httpBody = formatFormData(params)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMsg = parseErrorBody(data: data, statusCode: httpResponse.statusCode)
            // If refresh token was revoked by user or server, wipe local credentials
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                try? clearTokens()
            }
            throw TokenError.refreshFailed(errorMsg)
        }

        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(SpotifyTokenResponse.self, from: data)
        try storeTokens(tokenResponse)
        return tokenResponse.accessToken
    }

    // MARK: - Private Helpers

    private func formatFormData(_ parameters: [String: String]) -> Data {
        let bodyString = parameters.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(escapedKey)=\(escapedValue)"
        }.joined(separator: "&")
        return bodyString.data(using: .utf8) ?? Data()
    }

    private func parseErrorBody(data: Data, statusCode: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let errorDesc = json["error_description"] as? String {
                return "\(errorDesc) (HTTP \(statusCode))"
            }
            if let error = json["error"] as? String {
                return "\(error) (HTTP \(statusCode))"
            }
        }
        return "HTTP \(statusCode)"
    }
}
