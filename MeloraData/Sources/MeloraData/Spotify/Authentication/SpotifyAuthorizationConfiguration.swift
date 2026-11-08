import Foundation

/// Configuration object defining Spotify OAuth 2.0 PKCE settings and scopes.
///
/// Complies strictly with the Spotify Developer Policy:
/// - Never embeds a Client Secret.
/// - Requires only necessary metadata and playlist read scopes.
/// - Uses standard PKCE authorization code flow.
public struct SpotifyAuthorizationConfiguration: Sendable, Equatable {
    /// The Client ID registered in the Spotify Developer Dashboard.
    public let clientId: String

    /// Redirect URI registered in the Spotify Developer Dashboard (e.g., `melora://spotify-callback`).
    public let redirectUri: URL

    /// Requested OAuth permission scopes.
    public let scopes: [String]

    /// Spotify authorization endpoint URL.
    public let authorizationEndpoint: URL

    /// Spotify token exchange endpoint URL.
    public let tokenEndpoint: URL

    public init(
        clientId: String,
        redirectUri: URL,
        scopes: [String] = SpotifyAuthorizationConfiguration.defaultScopes,
        authorizationEndpoint: URL = URL(string: "https://accounts.spotify.com/authorize")!,
        tokenEndpoint: URL = URL(string: "https://accounts.spotify.com/api/token")!
    ) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.scopes = scopes
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
    }

    /// Standard metadata and playlist inspection scopes permitted in Spotify Development Mode.
    public static let defaultScopes: [String] = [
        "user-read-private",
        "user-read-email",
        "playlist-read-private",
        "playlist-read-collaborative",
        "user-library-read"
    ]

    /// Formats scopes into a single space-delimited string for the authorization request.
    public var scopeString: String {
        return scopes.joined(separator: " ")
    }
}
