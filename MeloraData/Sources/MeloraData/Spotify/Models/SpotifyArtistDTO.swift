import Foundation

/// Artist representation returned by Spotify Web API endpoints.
public struct SpotifyArtistDTO: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let genres: [String]?
    public let images: [SpotifyImageDTO]?
    public let popularity: Int?
    public let uri: String?

    public init(
        id: String,
        name: String,
        genres: [String]? = nil,
        images: [SpotifyImageDTO]? = nil,
        popularity: Int? = nil,
        uri: String? = nil
    ) {
        self.id = id
        self.name = name
        self.genres = genres
        self.images = images
        self.popularity = popularity
        self.uri = uri
    }

    /// Primary artwork image URL for the artist.
    public var primaryArtworkUrl: String? {
        return images?.first?.url
    }
}
