import Foundation

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/// Orchestrates the entire Spotify OAuth 2.0 PKCE authentication lifecycle.
public final class SpotifyOAuthManager: @unchecked Sendable {
    public let configuration: SpotifyAuthorizationConfiguration
    public let tokenManager: TokenManager

    private let lock = NSLock()
    private var pendingPKCE: PKCEPair?
    private var pendingState: String?

    public init(
        configuration: SpotifyAuthorizationConfiguration,
        tokenStorage: SecureTokenStorageProtocol,
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.tokenManager = TokenManager(
            configuration: configuration,
            tokenStorage: tokenStorage,
            urlSession: urlSession
        )
    }

    /// Constructs the authorization URL for user login in ASWebAuthenticationSession or external browser.
    public func createAuthorizationURL() -> URL {
        let pkce = PKCEGenerator.generate(length: 64)
        let state = PKCEGenerator.generateState(length: 32)

        lock.lock()
        self.pendingPKCE = pkce
        self.pendingState = state
        lock.unlock()

        var components = URLComponents(url: configuration.authorizationEndpoint, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "scope", value: configuration.scopeString),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectUri.absoluteString),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: pkce.codeChallengeMethod)
        ]

        return components.url!
    }

    /// Processes the redirect URL returned from Spotify authorization.
    public func handleRedirectURL(_ url: URL) async throws -> SpotifyTokenResponse {
        lock.lock()
        guard let expectedState = pendingState, let pkce = pendingPKCE else {
            lock.unlock()
            throw OAuthCallbackError.stateMismatch(expected: "Valid active state", received: nil)
        }
        lock.unlock()

        // 1. Validate state and extract code
        let code = try OAuthCallbackHandler.handleCallback(url: url, expectedState: expectedState)

        // 2. Exchange authorization code for tokens using the stored code_verifier
        let tokenResponse = try await tokenManager.exchangeCodeForTokens(
            code: code,
            codeVerifier: pkce.codeVerifier
        )

        // 3. Clear temporary state upon success
        lock.lock()
        self.pendingState = nil
        self.pendingPKCE = nil
        lock.unlock()

        return tokenResponse
    }

    /// Logs out and revokes stored session tokens.
    public func disconnect() async throws {
        lock.lock()
        self.pendingState = nil
        self.pendingPKCE = nil
        lock.unlock()
        try await tokenManager.clearTokens()
    }
}
