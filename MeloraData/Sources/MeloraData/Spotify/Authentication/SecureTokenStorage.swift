import Foundation

#if canImport(Security)
import Security
#endif

/// Contract for securely storing and retrieving OAuth authentication tokens.
public protocol SecureTokenStorageProtocol: AnyObject, Sendable {
    func saveTokens(accessToken: String, refreshToken: String?, expiresIn: Int) throws
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func getExpirationDate() -> Date?
    func isTokenExpired(bufferSeconds: TimeInterval) -> Bool
    func clearTokens() throws
}

extension SecureTokenStorageProtocol {
    public func isTokenExpired(bufferSeconds: TimeInterval = 60) -> Bool {
        guard let expiration = getExpirationDate() else { return true }
        // Proactively refresh bufferSeconds before actual expiration
        return Date().addingTimeInterval(bufferSeconds) >= expiration
    }
}

/// In-memory token storage implementation suitable for unit tests and portable environments.
public final class InMemoryTokenStorage: SecureTokenStorageProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var accessToken: String?
    private var refreshToken: String?
    private var expirationDate: Date?

    public init(accessToken: String? = nil, refreshToken: String? = nil, expirationDate: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationDate
    }

    public func saveTokens(accessToken: String, refreshToken: String?, expiresIn: Int) throws {
        lock.lock()
        defer { lock.unlock() }
        self.accessToken = accessToken
        if let rt = refreshToken {
            self.refreshToken = rt
        }
        self.expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    public func getAccessToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return accessToken
    }

    public func getRefreshToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return refreshToken
    }

    public func getExpirationDate() -> Date? {
        lock.lock()
        defer { lock.unlock() }
        return expirationDate
    }

    public func clearTokens() throws {
        lock.lock()
        defer { lock.unlock() }
        self.accessToken = nil
        self.refreshToken = nil
        self.expirationDate = nil
    }
}

/// Native iOS Keychain storage using `kSecClassGenericPassword` with `kSecAttrAccessibleAfterFirstUnlock`.
public final class KeychainTokenStorage: SecureTokenStorageProtocol, @unchecked Sendable {
    private let service: String
    private let accessGroup: String?

    private let accessTokenAccount = "melora.spotify.access_token"
    private let refreshTokenAccount = "melora.spotify.refresh_token"
    private let expirationAccount = "melora.spotify.token_expiration"

    public init(service: String = "com.melora.spotify.auth", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func saveTokens(accessToken: String, refreshToken: String?, expiresIn: Int) throws {
        #if canImport(Security)
        try saveToKeychain(key: accessTokenAccount, stringValue: accessToken)
        if let rt = refreshToken {
            try saveToKeychain(key: refreshTokenAccount, stringValue: rt)
        }
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        let timestampStr = String(expirationDate.timeIntervalSince1970)
        try saveToKeychain(key: expirationAccount, stringValue: timestampStr)
        #else
        // Platform without Security framework
        #endif
    }

    public func getAccessToken() -> String? {
        #if canImport(Security)
        return readFromKeychain(key: accessTokenAccount)
        #else
        return nil
        #endif
    }

    public func getRefreshToken() -> String? {
        #if canImport(Security)
        return readFromKeychain(key: refreshTokenAccount)
        #else
        return nil
        #endif
    }

    public func getExpirationDate() -> Date? {
        #if canImport(Security)
        guard let timestampStr = readFromKeychain(key: expirationAccount),
              let timestamp = Double(timestampStr) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
        #else
        return nil
        #endif
    }

    public func clearTokens() throws {
        #if canImport(Security)
        deleteFromKeychain(key: accessTokenAccount)
        deleteFromKeychain(key: refreshTokenAccount)
        deleteFromKeychain(key: expirationAccount)
        #endif
    }

    #if canImport(Security)
    private func saveToKeychain(key: String, stringValue: String) throws {
        guard let data = stringValue.data(using: .utf8) else { return }

        // Delete existing item first
        deleteFromKeychain(key: key)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [
                NSLocalizedDescriptionKey: "Failed to store item in Keychain (status: \(status))"
            ])
        }
    }

    private func readFromKeychain(key: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(key: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        SecItemDelete(query as CFDictionary)
    }
    #endif
}
