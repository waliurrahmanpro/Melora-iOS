import Foundation

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/// Orchestrates the entire Spotify OAuth 2.0 PKCE authentication lifecycle.
public final class SpotifyOAuthManager: @unchecked Sendable {
    public let configuration: SpotifyAuthorizationConfiguration
    public let tokenManager: TokenManager

    private let stateContainer = PendingStateContainer()

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

        stateContainer.setPending(pkce: pkce, state: state)

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
        // 1. Atomically validate state and consume the code verifier synchronously without holding locks across await
        let (code, codeVerifier) = try stateContainer.consumePending(for: url)

        // 2. Exchange authorization code for tokens asynchronously
        return try await tokenManager.exchangeCodeForTokens(
            code: code,
            codeVerifier: codeVerifier
        )
    }

    /// Logs out and revokes stored session tokens.
    public func disconnect() async throws {
        stateContainer.clear()
        try await tokenManager.clearTokens()
    }
}

// MARK: - Synchronous Concurrency-Safe State Container
private final class PendingStateContainer: @unchecked Sendable {
    private let lock = NSLock()
    private var pendingPKCE: PKCEPair?
    private var pendingState: String?

    func setPending(pkce: PKCEPair, state: String) {
        lock.lock()
        defer { lock.unlock() }
        self.pendingPKCE = pkce
        self.pendingState = state
    }

    /// Atomically validates the callback state, extracts the auth code, and invalidates pending credentials
    /// to prevent concurrent reuse or replay attacks.
    func consumePending(for url: URL) throws -> (code: String, codeVerifier: String) {
        lock.lock()
        defer { lock.unlock() }
        guard let expectedState = pendingState, let pkce = pendingPKCE else {
            throw OAuthCallbackError.stateMismatch(expected: "Valid active state", received: nil)
        }

        let code = try OAuthCallbackHandler.handleCallback(url: url, expectedState: expectedState)

        // Invalidate immediately upon successful consumption
        self.pendingState = nil
        self.pendingPKCE = nil
        return (code: code, codeVerifier: pkce.codeVerifier)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        self.pendingState = nil
        self.pendingPKCE = nil
    }
}
