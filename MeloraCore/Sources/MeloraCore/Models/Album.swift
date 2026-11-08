import Foundation

/// Domain model representing a music album.
public struct Album: Identifiable, Hashable, Codable, Sendable {
    /// Unique identifier for the album (UUID string).
    public let id: String

    /// Title of the album.
    public let title: String

    /// Foreign key referencing the primary artist ID.
    public let artistId: String?

    /// Name of the primary artist for fast display.
    public let artistName: String?

    /// Year of album release.
    public let releaseYear: Int?

    /// Local file path or URL for album cover artwork.
    public let artworkPath: String?

    /// Optional Spotify Album ID for metadata synchronization.
    public let spotifyId: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        artistId: String? = nil,
        artistName: String? = nil,
        releaseYear: Int? = nil,
        artworkPath: String? = nil,
        spotifyId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artistId = artistId
        self.artistName = artistName
        self.releaseYear = releaseYear
        self.artworkPath = artworkPath
        self.spotifyId = spotifyId
    }
}
