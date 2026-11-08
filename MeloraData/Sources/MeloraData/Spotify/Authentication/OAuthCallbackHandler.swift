import Foundation

/// Errors that can occur when parsing or validating an incoming OAuth redirect URL.
public enum OAuthCallbackError: Error, LocalizedError, Equatable, Sendable {
    case invalidCallbackURL(String)
    case missingAuthorizationCode
    case stateMismatch(expected: String, received: String?)
    case accessDenied(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCallbackURL(let url):
            return "Invalid OAuth callback URL: \(url)"
        case .missingAuthorizationCode:
            return "OAuth callback did not contain an authorization code"
        case .stateMismatch(let expected, let received):
            return "OAuth state validation failed (CSRF protection). Expected '\(expected)', received '\(received ?? "nil")'"
        case .accessDenied(let desc):
            return "User or server denied authorization: \(desc)"
        case .serverError(let desc):
            return "OAuth authorization server returned error: \(desc)"
        }
    }
}

/// Validates incoming OAuth redirect URLs and extracts the authorization code.
public enum OAuthCallbackHandler {

    /// Parses the incoming redirect URL and returns the authorization code if valid.
    ///
    /// - Parameters:
    ///   - url: The callback URL passed into the application.
    ///   - expectedState: The state value generated before launching the authorization session.
    /// - Returns: The extracted authorization code string.
    public static func handleCallback(url: URL, expectedState: String) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw OAuthCallbackError.invalidCallbackURL(url.absoluteString)
        }

        let queryItems = components.queryItems ?? []
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value != nil ? (item.name, item.value!) : nil
        })

        // Check for error parameters returned by Spotify
        if let error = queryDict["error"] {
            let description = queryDict["error_description"] ?? error
            if error == "access_denied" {
                throw OAuthCallbackError.accessDenied(description)
            } else {
                throw OAuthCallbackError.serverError(description)
            }
        }

        // Validate CSRF state parameter
        let receivedState = queryDict["state"]
        guard let state = receivedState, state == expectedState else {
            throw OAuthCallbackError.stateMismatch(expected: expectedState, received: receivedState)
        }

        // Extract authorization code
        guard let code = queryDict["code"], !code.isEmpty else {
            throw OAuthCallbackError.missingAuthorizationCode
        }

        return code
    }
}
