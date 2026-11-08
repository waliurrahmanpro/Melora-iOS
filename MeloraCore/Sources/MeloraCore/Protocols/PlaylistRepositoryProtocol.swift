import Foundation

/// Repository contract managing playlists and playlist track ordering.
public protocol PlaylistRepositoryProtocol: Sendable {
    /// Retrieves all user and imported playlists.
    func getPlaylists() throws -> [Playlist]

    /// Retrieves a single playlist by its ID.
    func getPlaylist(byId id: String) throws -> Playlist?

    /// Retrieves an imported playlist by its original Spotify playlist ID.
    func getPlaylistBySpotifyId(_ spotifyPlaylistId: String) throws -> Playlist?

    /// Creates a new empty playlist.
    func createPlaylist(_ playlist: Playlist) throws

    /// Updates playlist properties (title, description, custom artwork).
    func updatePlaylist(_ playlist: Playlist) throws

    /// Deletes a playlist by ID (cascades and deletes playlist_tracks entries).
    func deletePlaylist(byId id: String) throws

    /// Appends a track to the end of a playlist.
    func addTrack(trackId: String, toPlaylistId playlistId: String) throws

    /// Inserts a track at a specific zero-based position in a playlist.
    func insertTrack(trackId: String, intoPlaylistId playlistId: String, atPosition position: Int) throws

    /// Removes a track from a playlist and compacts remaining positions.
    func removeTrack(trackId: String, fromPlaylistId playlistId: String) throws

    /// Reorders a track within a playlist from an old position to a new position.
    func reorderTrack(inPlaylistId playlistId: String, fromPosition: Int, toPosition: Int) throws

    /// Retrieves all tracks belonging to a playlist, preserving exact position order.
    func getTracksForPlaylist(playlistId: String) throws -> [Track]
}
