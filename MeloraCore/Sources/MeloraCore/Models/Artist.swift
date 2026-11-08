import Foundation

/// Domain model representing a music artist.
public struct Artist: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier for the artist (UUID string).
    public let id: String

    /// Name of the artist.
    public let name: String

    /// Optional Spotify Artist ID for metadata exploration and artwork discovery.
    public let spotifyId: String?

    /// Remote or local artwork URL for artist image.
    public let artworkUrl: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        spotifyId: String? = nil,
        artworkUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.spotifyId = spotifyId
        self.artworkUrl = artworkUrl
    }
}
