import Foundation
import MeloraCore

/// Pure mapper converting Spotify DTO network models to Melora domain entities.
public enum SpotifyModelMapper {

    /// Maps a SpotifyPlaylistDTO to domain SpotifyPlaylistMetadata.
    public static func mapToPlaylistMetadata(_ dto: SpotifyPlaylistDTO) -> SpotifyPlaylistMetadata {
        return SpotifyPlaylistMetadata(
            id: dto.id,
            name: dto.name,
            description: dto.description,
            artworkUrl: dto.primaryArtworkUrl,
            totalTracks: dto.totalTracks,
            ownerName: dto.owner?.displayName
        )
    }

    /// Maps a SpotifyTrackDTO to domain SpotifyTrackMetadata.
    public static func mapToTrackMetadata(_ dto: SpotifyTrackDTO) -> SpotifyTrackMetadata {
        return SpotifyTrackMetadata(
            id: dto.id,
            title: dto.name,
            artistName: dto.primaryArtistName,
            albumTitle: dto.album?.name,
            durationMs: dto.durationMs,
            artworkUrl: dto.artworkUrl,
            isExplicit: dto.explicit ?? false
        )
    }

    /// Maps a SpotifyArtistDTO to domain Artist.
    public static func mapToArtist(_ dto: SpotifyArtistDTO) -> Artist {
        return Artist(
            id: UUID().uuidString,
            name: dto.name,
            spotifyId: dto.id,
            artworkUrl: dto.primaryArtworkUrl
        )
    }

    /// Maps a SpotifyAlbumDTO to domain Album.
    public static func mapToAlbum(_ dto: SpotifyAlbumDTO) -> Album {
        return Album(
            id: UUID().uuidString,
            title: dto.name,
            artistId: nil,
            artistName: dto.artists?.first?.name,
            releaseYear: dto.releaseYear,
            artworkPath: dto.primaryArtworkUrl,
            spotifyId: dto.id
        )
    }
}
