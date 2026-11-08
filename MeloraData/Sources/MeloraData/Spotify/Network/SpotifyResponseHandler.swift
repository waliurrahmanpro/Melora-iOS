import Foundation

/// Internal model parsing Spotify Web API error payloads.
private struct SpotifyErrorEnvelope: Codable {
    struct ErrorDetail: Codable {
        let status: Int
        let message: String
    }
    let error: ErrorDetail
}

/// Validates HTTP status codes and decodes Spotify Web API JSON responses.
public enum SpotifyResponseHandler {

    /// Validates an HTTP response and decodes the expected payload.
    ///
    /// - Parameters:
    ///   - data: Raw response payload.
    ///   - response: HTTPURLResponse metadata.
    ///   - decoder: JSONDecoder instance.
    /// - Returns: Decoded entity of type `T`.
    public static func handleResponse<T: Decodable & Sendable>(
        data: Data,
        response: URLResponse,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyAPIError.invalidResponse
        }

        let statusCode = httpResponse.statusCode

        switch statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw SpotifyAPIError.decodingError(message: error.localizedDescription)
            }

        case 401:
            let message = extractErrorMessage(from: data) ?? "The access token has expired or is invalid."
            throw SpotifyAPIError.unauthorized(message: message)

        case 403:
            let message = extractErrorMessage(from: data) ?? "Forbidden. User may not be authorized in Spotify Development Mode."
            throw SpotifyAPIError.forbidden(message: message)

        case 404:
            let message = extractErrorMessage(from: data) ?? "Resource not found on Spotify Web API."
            throw SpotifyAPIError.notFound(message: message)

        case 429:
            var retrySeconds = 5
            if let headerVal = httpResponse.value(forHTTPHeaderField: "Retry-After"),
               let parsed = Int(headerVal) {
                retrySeconds = parsed
            }
            throw SpotifyAPIError.rateLimited(retryAfterSeconds: retrySeconds)

        case 500...599:
            let message = extractErrorMessage(from: data) ?? "Spotify internal server error."
            throw SpotifyAPIError.serverError(statusCode: statusCode, message: message)

        default:
            let message = extractErrorMessage(from: data) ?? "Unexpected HTTP status."
            throw SpotifyAPIError.clientError(statusCode: statusCode, message: message)
        }
    }

    private static func extractErrorMessage(from data: Data) -> String? {
        if let envelope = try? JSONDecoder().decode(SpotifyErrorEnvelope.self, from: data) {
            return envelope.error.message
        }
        return nil
    }
}
