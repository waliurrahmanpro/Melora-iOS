import Foundation
import MeloraCore

/// Supported sorting options for the user's music library.
public enum TrackSortOption: Sendable {
    case titleAscending
    case titleDescending
    case artistAscending
    case artistDescending
    case dateAddedNewest
    case dateAddedOldest
    case durationShortest
    case durationLongest
}

/// Service providing library search, filtering, sorting, and safe track deletion.
public final class LibraryFilterService: Sendable {
    private let trackRepository: TrackRepositoryProtocol
    private let storageManager: LocalFileStorageManager

    public init(
        trackRepository: TrackRepositoryProtocol,
        storageManager: LocalFileStorageManager
    ) {
        self.trackRepository = trackRepository
        self.storageManager = storageManager
    }

    /// Fetches recently added tracks, ordered by creation date descending.
    public func getRecentlyAdded(limit: Int = 20) throws -> [Track] {
        return try trackRepository.getRecentlyAddedTracks(limit: limit)
    }

    /// Searches tracks by title, artist, or album matching a query string.
    public func searchTracks(query: String) throws -> [Track] {
        return try trackRepository.searchTracks(query: query)
    }

    /// Filters a list of tracks by optional artist, album, and audio format criteria.
    public func filterTracks(
        tracks: [Track],
        artistName: String? = nil,
        albumTitle: String? = nil,
        audioFormat: AudioFormat? = nil
    ) -> [Track] {
        return tracks.filter { track in
            if let artist = artistName, !artist.isEmpty {
                if track.artistName.localizedCaseInsensitiveCompare(artist) != .orderedSame {
                    return false
                }
            }
            if let album = albumTitle, !album.isEmpty {
                if track.albumTitle?.localizedCaseInsensitiveCompare(album) != .orderedSame {
                    return false
                }
            }
            if let format = audioFormat {
                if track.audioFormat != format {
                    return false
                }
            }
            return true
        }
    }

    /// Sorts tracks based on the specified sort option.
    public func sortTracks(_ tracks: [Track], by sortOption: TrackSortOption) -> [Track] {
        switch sortOption {
        case .titleAscending:
            return tracks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDescending:
            return tracks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .artistAscending:
            return tracks.sorted { $0.artistName.localizedCaseInsensitiveCompare($1.artistName) == .orderedAscending }
        case .artistDescending:
            return tracks.sorted { $0.artistName.localizedCaseInsensitiveCompare($1.artistName) == .orderedDescending }
        case .dateAddedNewest:
            return tracks.sorted { $0.createdAt > $1.createdAt }
        case .dateAddedOldest:
            return tracks.sorted { $0.createdAt < $1.createdAt }
        case .durationShortest:
            return tracks.sorted { $0.durationMs < $1.durationMs }
        case .durationLongest:
            return tracks.sorted { $0.durationMs > $1.durationMs }
        }
    }

    /// Safely removes a track from the SQLite database and deletes its physical sandbox files.
    public func safelyDeleteTrack(_ track: Track) throws {
        // 1. Delete from database (cascades in playlists and history)
        try trackRepository.deleteTrack(byId: track.id)

        // 2. Delete audio file from sandbox
        try? storageManager.deleteFile(atRelativePath: track.filePath)

        // 3. Delete artwork thumbnail if present
        if let artworkPath = track.artworkPath {
            try? storageManager.deleteFile(atRelativePath: artworkPath)
        }
    }
}
