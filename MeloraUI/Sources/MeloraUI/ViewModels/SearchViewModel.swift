import Foundation
import MeloraCore
import MeloraData

#if canImport(Observation)
import Observation
#endif

/// Search scope filter categories.
public enum SearchCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case tracks = "Tracks"
    case artists = "Artists"
    case albums = "Albums"
    case spotify = "Spotify"

    public var id: String { rawValue }
}

/// ViewModel coordinating local database searches and remote Spotify metadata lookups.
@Observable
public final class SearchViewModel: @unchecked Sendable {
    public let trackRepository: TrackRepositoryProtocol
    public let spotifyService: SpotifyServiceProtocol?

    public var query: String = ""
    public var selectedCategory: SearchCategory = .all
    public var localTracks: [Track] = []
    public var localArtists: [String] = []
    public var localAlbums: [String] = []
    public var spotifyResults: [SpotifyTrackMetadata] = []

    public var isSearching: Bool = false
    public var errorMessage: String?

    public init(
        trackRepository: TrackRepositoryProtocol,
        spotifyService: SpotifyServiceProtocol? = nil
    ) {
        self.trackRepository = trackRepository
        self.spotifyService = spotifyService
    }

    public var isSpotifyConnected: Bool {
        return spotifyService?.isAuthenticated == true
    }

    public func executeSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearResults()
            return
        }

        self.isSearching = true
        self.errorMessage = nil

        do {
            // Local track search
            let tracks = try trackRepository.searchTracks(query: trimmed)
            self.localTracks = tracks

            // Filter matching local artists and albums
            let all = try trackRepository.getAllTracks()
            self.localArtists = Array(Set(all.map { $0.artistName }.filter {
                $0.localizedCaseInsensitiveContains(trimmed)
            })).sorted()

            self.localAlbums = Array(Set(all.compactMap { $0.albumTitle }.filter {
                $0.localizedCaseInsensitiveContains(trimmed)
            })).sorted()

            // If Spotify is authenticated and category is All or Spotify, search catalog
            if isSpotifyConnected && (selectedCategory == .all || selectedCategory == .spotify) {
                Task {
                    do {
                        let remote = try await self.spotifyService?.searchCatalog(query: trimmed, limit: 10) ?? []
                        await MainActor.run {
                            self.spotifyResults = remote
                            self.isSearching = false
                        }
                    } catch {
                        await MainActor.run {
                            self.isSearching = false
                        }
                    }
                }
            } else {
                self.isSearching = false
            }
        } catch {
            self.errorMessage = "Search failed: \(error.localizedDescription)"
            self.isSearching = false
        }
    }

    public func clearResults() {
        self.localTracks.removeAll()
        self.localArtists.removeAll()
        self.localAlbums.removeAll()
        self.spotifyResults.removeAll()
        self.isSearching = false
    }
}
