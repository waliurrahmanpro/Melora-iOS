import Foundation

/// Repository contract managing persistence and queries for audio tracks.
public protocol TrackRepositoryProtocol: Sendable {
    /// Retrieves a track by its unique UUID.
    func getTrack(byId id: String) throws -> Track?

    /// Retrieves all tracks stored in the library, sorted alphabetically by title.
    func getAllTracks() throws -> [Track]

    /// Retrieves a paginated slice of tracks.
    func getTracks(page: Int, pageSize: Int) throws -> [Track]

    /// Performs a case-insensitive substring search across track title and artist name.
    func searchTracks(query: String) throws -> [Track]

    /// Retrieves all tracks associated with a specific artist name.
    func getTracksByArtist(name: String) throws -> [Track]

    /// Retrieves all tracks belonging to a given album title.
    func getTracksByAlbum(title: String) throws -> [Track]

    /// Retrieves a track by its linked Spotify Track ID.
    func getTrackBySpotifyId(_ spotifyId: String) throws -> Track?

    /// Retrieves a track by its SHA-256 file content hash (used for duplicate detection).
    func getTrackByFileHash(_ fileHash: String) throws -> Track?

    /// Retrieves the most recently added tracks, ordered by created_at DESC.
    func getRecentlyAddedTracks(limit: Int) throws -> [Track]

    /// Inserts a new track into the library.
    func insertTrack(_ track: Track) throws

    /// Inserts multiple tracks in a single atomic transaction.
    func insertTracks(_ tracks: [Track]) throws

    /// Updates existing track metadata (e.g. ID3 tags, artwork path, Spotify mapping).
    func updateTrack(_ track: Track) throws

    /// Removes a track by its ID and cascades deletions in playlists and history.
    func deleteTrack(byId id: String) throws

    /// Returns the total number of audio tracks in the local library.
    func countTracks() throws -> Int
}
