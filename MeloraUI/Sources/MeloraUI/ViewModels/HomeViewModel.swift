import Foundation
import MeloraCore
import MeloraData

#if canImport(Observation)
import Observation
#endif

/// ViewModel powering the Home screen with real SQLite library data.
@Observable
public final class HomeViewModel: @unchecked Sendable {
    public let trackRepository: TrackRepositoryProtocol
    public let playlistRepository: PlaylistRepositoryProtocol
    public let historyRepository: PlaybackHistoryRepositoryProtocol

    public var recentlyPlayedTracks: [Track] = []
    public var recentlyAddedTracks: [Track] = []
    public var playlists: [Playlist] = []
    public var topArtists: [String] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    public init(
        trackRepository: TrackRepositoryProtocol,
        playlistRepository: PlaylistRepositoryProtocol,
        historyRepository: PlaybackHistoryRepositoryProtocol
    ) {
        self.trackRepository = trackRepository
        self.playlistRepository = playlistRepository
        self.historyRepository = historyRepository
    }

    /// Computed dynamic greeting based on current local hour.
    public var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 18 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    public func loadData() {
        self.isLoading = true
        self.errorMessage = nil

        do {
            // 1. Load recently added tracks
            self.recentlyAddedTracks = try trackRepository.getRecentlyAddedTracks(limit: 10)

            // 2. Load playlists
            self.playlists = try playlistRepository.getPlaylists()

            // 3. Load recently played from history
            let historyEntries = try historyRepository.getRecentHistory(limit: 10)
            self.recentlyPlayedTracks = historyEntries.compactMap { $0.track }

            // 4. Derive top artists from local tracks
            let allTracks = try trackRepository.getAllTracks()
            let artistCounts = Dictionary(grouping: allTracks, by: { $0.artistName })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            self.topArtists = Array(artistCounts.prefix(6).map { $0.key })

            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load library: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}
