import Foundation

/// Album representation returned by Spotify Web API endpoints.
public struct SpotifyAlbumDTO: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let albumType: String?
    public let totalTracks: Int?
    public let images: [SpotifyImageDTO]?
    public let releaseDate: String?
    public let releaseDatePrecision: String?
    public let artists: [SpotifyArtistDTO]?
    public let uri: String?

    public init(
        id: String,
        name: String,
        albumType: String? = nil,
        totalTracks: Int? = nil,
        images: [SpotifyImageDTO]? = nil,
        releaseDate: String? = nil,
        releaseDatePrecision: String? = nil,
        artists: [SpotifyArtistDTO]? = nil,
        uri: String? = nil
    ) {
        self.id = id
        self.name = name
        self.albumType = albumType
        self.totalTracks = totalTracks
        self.images = images
        self.releaseDate = releaseDate
        self.releaseDatePrecision = releaseDatePrecision
        self.artists = artists
        self.uri = uri
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case albumType = "album_type"
        case totalTracks = "total_tracks"
        case images
        case releaseDate = "release_date"
        case releaseDatePrecision = "release_date_precision"
        case artists
        case uri
    }

    /// Primary artwork image URL for the album.
    public var primaryArtworkUrl: String? {
        return images?.first?.url
    }

    /// Extracted release year if the release date contains a 4-digit year.
    public var releaseYear: Int? {
        guard let releaseDate = releaseDate, releaseDate.count >= 4 else { return nil }
        return Int(releaseDate.prefix(4))
    }
}
