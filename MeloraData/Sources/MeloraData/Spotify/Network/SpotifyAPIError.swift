import Foundation

/// Structured errors returned by the Spotify Web API or networking layer.
public enum SpotifyAPIError: Error, LocalizedError, Sendable {
    case unauthorized(message: String)
    case forbidden(message: String)
    case notFound(message: String)
    case rateLimited(retryAfterSeconds: Int)
    case clientError(statusCode: Int, message: String)
    case serverError(statusCode: Int, message: String)
    case decodingError(message: String)
    case networkError(message: String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .unauthorized(let msg):
            return "Spotify 401 Unauthorized: \(msg). Session may have expired."
        case .forbidden(let msg):
            return "Spotify 403 Forbidden: \(msg). Development Mode may restrict access to unauthorized users."
        case .notFound(let msg):
            return "Spotify 404 Not Found: \(msg)"
        case .rateLimited(let retryAfter):
            return "Spotify 429 Rate Limited. Please retry after \(retryAfter) seconds."
        case .clientError(let code, let msg):
            return "Spotify Client Error (HTTP \(code)): \(msg)"
        case .serverError(let code, let msg):
            return "Spotify Server Error (HTTP \(code)): \(msg)"
        case .decodingError(let msg):
            return "Failed to parse Spotify API response: \(msg)"
        case .networkError(let msg):
            return "Network error connecting to Spotify: \(msg)"
        case .invalidResponse:
            return "Received non-HTTP response from Spotify Web API."
        }
    }

    /// Convenience check for rate limiting.
    public var isRateLimited: Bool {
        if case .rateLimited = self { return true }
        return false
    }

    /// Extracted retry-after interval if rate limited.
    public var retryAfterSeconds: Int? {
        if case .rateLimited(let sec) = self { return sec }
        return nil
    }
}
