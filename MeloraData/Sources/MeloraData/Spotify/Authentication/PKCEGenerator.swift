import Foundation

#if canImport(CryptoKit)
import CryptoKit
#endif

/// Generates cryptographically secure OAuth 2.0 PKCE (Proof Key for Code Exchange) parameters.
///
/// Complies with RFC 7636:
/// - Code Verifier: High-entropy cryptographic random string (43 to 128 characters, unreserved URL characters).
/// - Code Challenge: Base64URL-encoded SHA-256 hash of the verifier without padding.
public struct PKCEPair: Sendable, Equatable {
    /// The high-entropy secret string to be kept client-side until token exchange.
    public let codeVerifier: String

    /// The transformed challenge sent in the authorization request.
    public let codeChallenge: String

    /// Challenge method (always "S256").
    public let codeChallengeMethod: String = "S256"

    public init(codeVerifier: String, codeChallenge: String) {
        self.codeVerifier = codeVerifier
        self.codeChallenge = codeChallenge
    }
}

public enum PKCEGenerator {
    private static let unreservedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"

    /// Generates a new cryptographically random PKCE code verifier and S256 code challenge.
    ///
    /// - Parameter length: Character count of the verifier (must be between 43 and 128; defaults to 64).
    /// - Returns: A valid `PKCEPair`.
    public static func generate(length: Int = 64) -> PKCEPair {
        let clampedLength = min(max(length, 43), 128)
        let verifier = generateRandomString(length: clampedLength)
        let challenge = computeS256Challenge(for: verifier)
        return PKCEPair(codeVerifier: verifier, codeChallenge: challenge)
    }

    /// Generates a random cryptographic state string for OAuth CSRF protection.
    public static func generateState(length: Int = 32) -> String {
        return generateRandomString(length: length)
    }

    /// Computes the Base64URL-encoded SHA-256 hash of a string.
    public static func computeS256Challenge(for verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else {
            return ""
        }

        #if canImport(CryptoKit)
        let hash = CryptoKit.SHA256.hash(data: data)
        let hashData = Data(hash)
        return base64URLEncode(hashData)
        #else
        let hashData = PortableSHA256.hash(data)
        return base64URLEncode(hashData)
        #endif
    }

    /// Converts raw data into Base64URL format (replacing + with -, / with _, and stripping = padding).
    public static func base64URLEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }

    private static func generateRandomString(length: Int) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        #if canImport(Security)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
        #else
        // Fallback random byte generation
        for i in 0..<length {
            randomBytes[i] = UInt8.random(in: 0...255)
        }
        #endif

        let characterArray = Array(unreservedCharacters)
        var result = ""
        result.reserveCapacity(length)
        for byte in randomBytes {
            let index = Int(byte) % characterArray.count
            result.append(characterArray[index])
        }
        return result
    }
}

// MARK: - Portable Fallback SHA256 (for environments where CryptoKit is not available)

#if !canImport(CryptoKit)
enum PortableSHA256 {
    static func hash(_ input: Data) -> Data {
        // Portable FIPS 180-2 SHA-256 implementation
        var h0: UInt32 = 0x6a09e667
        var h1: UInt32 = 0xbb67ae85
        var h2: UInt32 = 0x3c6ef372
        var h3: UInt32 = 0xa54ff53a
        var h4: UInt32 = 0x510e527f
        var h5: UInt32 = 0x9b05688c
        var h6: UInt32 = 0x1f83d9ab
        var h7: UInt32 = 0x5be0cd19

        let k: [UInt32] = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
        ]

        var message = input
        let bitLength = UInt64(message.count) * 8
        message.append(0x80)
        while (message.count % 64) != 56 {
            message.append(0x00)
        }
        var bigEndianBitLength = bitLength.bigEndian
        withUnsafeBytes(of: &bigEndianBitLength) { message.append(contentsOf: $0) }

        for chunkStart in stride(from: 0, to: message.count, by: 64) {
            var w = [UInt32](repeating: 0, count: 64)
            for i in 0..<16 {
                let offset = chunkStart + (i * 4)
                w[i] = (UInt32(message[offset]) << 24) |
                       (UInt32(message[offset + 1]) << 16) |
                       (UInt32(message[offset + 2]) << 8) |
                       UInt32(message[offset + 3])
            }
            for i in 16..<64 {
                let s0 = (w[i - 15] >> 7 | w[i - 15] << 25) ^ (w[i - 15] >> 18 | w[i - 15] << 14) ^ (w[i - 15] >> 3)
                let s1 = (w[i - 2] >> 17 | w[i - 2] << 15) ^ (w[i - 2] >> 19 | w[i - 2] << 13) ^ (w[i - 2] >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }

            var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7
            for i in 0..<64 {
                let s1 = (e >> 6 | e << 26) ^ (e >> 11 | e << 21) ^ (e >> 25 | e << 7)
                let ch = (e & f) ^ (~e & g)
                let temp1 = h &+ s1 &+ ch &+ k[i] &+ w[i]
                let s0 = (a >> 2 | a << 30) ^ (a >> 13 | a << 19) ^ (a >> 22 | a << 10)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj

                h = g; g = f; f = e; e = d &+ temp1; d = c; c = b; b = a; a = temp1 &+ temp2
            }

            h0 = h0 &+ a; h1 = h1 &+ b; h2 = h2 &+ c; h3 = h3 &+ d
            h4 = h4 &+ e; h5 = h5 &+ f; h6 = h6 &+ g; h7 = h7 &+ h
        }

        var result = Data()
        for hVal in [h0, h1, h2, h3, h4, h5, h6, h7] {
            var be = hVal.bigEndian
            withUnsafeBytes(of: &be) { result.append(contentsOf: $0) }
        }
        return result
    }
}
#endif
