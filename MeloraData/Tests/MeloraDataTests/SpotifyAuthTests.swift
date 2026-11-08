import Foundation
import Testing
@testable import MeloraCore
@testable import MeloraData

@Suite("Spotify Authentication & PKCE Tests")
struct SpotifyAuthTests {

    @Test("PKCE code verifier and S256 challenge generation")
    func testPKCEGeneration() {
        let pkce = PKCEGenerator.generate(length: 64)

        // Verifier length and entropy
        #expect(pkce.codeVerifier.count == 64)
        #expect(pkce.codeChallengeMethod == "S256")
        #expect(!pkce.codeChallenge.isEmpty)

        // Verifier must only contain RFC 7636 unreserved characters
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        for unicodeScalar in pkce.codeVerifier.unicodeScalars {
            #expect(allowed.contains(unicodeScalar))
        }

        // Base64URL string must not contain +, /, or =
        #expect(!pkce.codeChallenge.contains("+"))
        #expect(!pkce.codeChallenge.contains("/"))
        #expect(!pkce.codeChallenge.contains("="))
    }

    @Test("RFC 7636 Known S256 Vector")
    func testRFC7636Vector() {
        // RFC 7636 Appendix B Test Vector
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let expectedChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

        let computedChallenge = PKCEGenerator.computeS256Challenge(for: verifier)
        #expect(computedChallenge == expectedChallenge)
    }

    @Test("OAuth state generation and validation")
    func testOAuthStateHandling() throws {
        let state = PKCEGenerator.generateState(length: 32)
        #expect(state.count == 32)

        // Valid callback URL with matching state
        let validURL = URL(string: "melora://spotify-callback?code=AQD123xyz&state=\(state)")!
        let extractedCode = try OAuthCallbackHandler.handleCallback(url: validURL, expectedState: state)
        #expect(extractedCode == "AQD123xyz")

        // Mismatched state should throw stateMismatch error (CSRF protection)
        let tamperedURL = URL(string: "melora://spotify-callback?code=AQD123xyz&state=wrong_state")!
        #expect(throws: OAuthCallbackError.self) {
            try OAuthCallbackHandler.handleCallback(url: tamperedURL, expectedState: state)
        }

        // Access denied error
        let deniedURL = URL(string: "melora://spotify-callback?error=access_denied&error_description=User%20denied&state=\(state)")!
        #expect(throws: OAuthCallbackError.self) {
            try OAuthCallbackHandler.handleCallback(url: deniedURL, expectedState: state)
        }
    }

    @Test("InMemoryTokenStorage token lifecycle and expiration")
    func testTokenStorage() throws {
        let storage = InMemoryTokenStorage()
        #expect(storage.getAccessToken() == nil)
        #expect(storage.getRefreshToken() == nil)
        #expect(storage.isTokenExpired() == true)

        // Save active token with 1 hour expiration
        try storage.saveTokens(accessToken: "access_123", refreshToken: "refresh_456", expiresIn: 3600)
        #expect(storage.getAccessToken() == "access_123")
        #expect(storage.getRefreshToken() == "refresh_456")
        #expect(storage.isTokenExpired(bufferSeconds: 60) == false)

        // Clear tokens
        try storage.clearTokens()
        #expect(storage.getAccessToken() == nil)
        #expect(storage.getRefreshToken() == nil)
        #expect(storage.isTokenExpired() == true)
    }
}
