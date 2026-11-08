import Foundation

/// OAuth 2.0 Token response payload returned by https://accounts.spotify.com/api/token.
public struct SpotifyTokenResponse: Codable, Sendable, Equatable {
    /// Bearer access token used to authenticate Web API requests.
    public let accessToken: String

    /// Typically "Bearer".
    public let tokenType: String

    /// Space-separated list of scopes granted for this access token.
    public let scope: String

    /// Lifespan of the access token in seconds (typically 3600).
    public let expiresIn: Int

    /// Refresh token used to obtain new access tokens (only provided on initial code exchange).
    public let refreshToken: String?

    public init(
        accessToken: String,
        tokenType: String = "Bearer",
        scope: String = "",
        expiresIn: Int = 3600,
        refreshToken: String? = nil
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.scope = scope
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
