import Foundation

/// Image entity returned across Spotify API endpoints.
public struct SpotifyImageDTO: Codable, Sendable, Equatable, Hashable {
    public let url: String
    public let height: Int?
    public let width: Int?

    public init(url: String, height: Int? = nil, width: Int? = nil) {
        self.url = url
        self.height = height
        self.width = width
    }
}

/// Generic paging wrapper object returned by Spotify Web API endpoints.
public struct SpotifyPagingDTO<T: Codable & Sendable>: Codable, Sendable {
    public let href: String
    public let items: [T]
    public let limit: Int
    public let next: String?
    public let offset: Int
    public let previous: String?
    public let total: Int

    public init(
        href: String = "",
        items: [T],
        limit: Int = 20,
        next: String? = nil,
        offset: Int = 0,
        previous: String? = nil,
        total: Int = 0
    ) {
        self.href = href
        self.items = items
        self.limit = limit
        self.next = next
        self.offset = offset
        self.previous = previous
        self.total = total
    }
}

extension SpotifyPagingDTO: Equatable where T: Equatable {}
extension SpotifyPagingDTO: Hashable where T: Hashable {}

/// User profile object returned by GET https://api.spotify.com/v1/me.
public struct SpotifyUserProfile: Codable, Sendable, Equatable {
    public let id: String
    public let displayName: String?
    public let email: String?
    public let country: String?
    public let product: String? // "premium", "free", "open"
    public let images: [SpotifyImageDTO]?
    public let uri: String?

    public init(
        id: String,
        displayName: String? = nil,
        email: String? = nil,
        country: String? = nil,
        product: String? = nil,
        images: [SpotifyImageDTO]? = nil,
        uri: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.country = country
        self.product = product
        self.images = images
        self.uri = uri
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case country
        case product
        case images
        case uri
    }

    /// Indicates whether the user account has an active Spotify Premium subscription.
    public var isPremium: Bool {
        return product?.lowercased() == "premium"
    }

    /// Primary profile image URL if available.
    public var avatarUrl: String? {
        return images?.first?.url
    }
}
