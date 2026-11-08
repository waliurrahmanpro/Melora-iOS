import Foundation
import Testing
@testable import MeloraCore
@testable import MeloraData

@Suite("Spotify Network & Rate Limiter Tests")
struct SpotifyNetworkTests {

    @Test("SpotifyRequestBuilder generates valid headers and query params")
    func testRequestBuilder() throws {
        let endpoint = SpotifyEndpoint.search(query: "Daft Punk", types: ["track", "artist"], limit: 10, offset: 0)
        let request = try SpotifyRequestBuilder.buildRequest(for: endpoint, accessToken: "test_token_abc")

        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test_token_abc")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")

        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.contains("/v1/search"))
        #expect(urlString.contains("q=Daft%20Punk") || urlString.contains("q=Daft+Punk"))
        #expect(urlString.contains("limit=10"))
    }

    @Test("SpotifyRateLimiter tracks cooldown and inspects 429 response")
    func testRateLimiter() async {
        let rateLimiter = SpotifyRateLimiter()
        #expect(await rateLimiter.isRateLimited == false)

        // Simulate 429 HTTP response with Retry-After: 3
        let response = HTTPURLResponse(
            url: URL(string: "https://api.spotify.com/v1/me")!,
            statusCode: 429,
            httpVersion: "HTTP/1.1",
            headerFields: ["Retry-After": "3"]
        )!

        let retryAfter = await rateLimiter.inspectResponse(response)
        #expect(retryAfter == 3)
        #expect(await rateLimiter.isRateLimited == true)
        #expect(await rateLimiter.remainingCooldownSeconds > 0)

        // Reset
        await rateLimiter.reset()
        #expect(await rateLimiter.isRateLimited == false)
    }

    @Test("SpotifyResponseHandler maps status codes to structured errors")
    func testResponseHandlerErrors() {
        let url = URL(string: "https://api.spotify.com/v1/me")!

        // 401 Unauthorized
        let resp401 = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!
        #expect(throws: SpotifyAPIError.self) {
            let _: SpotifyUserProfile = try SpotifyResponseHandler.handleResponse(data: Data(), response: resp401)
        }

        // 403 Forbidden
        let resp403 = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!
        #expect(throws: SpotifyAPIError.self) {
            let _: SpotifyUserProfile = try SpotifyResponseHandler.handleResponse(data: Data(), response: resp403)
        }

        // 429 Rate Limited with Retry-After header
        let resp429 = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: ["Retry-After": "8"])!
        do {
            let _: SpotifyUserProfile = try SpotifyResponseHandler.handleResponse(data: Data(), response: resp429)
            Issue.record("Expected 429 rate limit error")
        } catch let error as SpotifyAPIError {
            #expect(error.isRateLimited == true)
            #expect(error.retryAfterSeconds == 8)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
