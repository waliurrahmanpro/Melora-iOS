import Foundation
import Testing
@testable import MeloraCore
@testable import MeloraData
@testable import MeloraAudio
@testable import MeloraUI

@Suite("SwiftUI ViewModels Tests")
struct ViewModelTests {

    @Test("PlayerViewModel controls and state bindings")
    func testPlayerViewModel() {
        let mockEngine = MockAudioPlayerEngine()
        let coordinator = AudioPlaybackCoordinator(audioEngine: mockEngine)
        let playerVM = PlayerViewModel(coordinator: coordinator)

        let track1 = Track(id: "t1", title: "Track 1", artistName: "Artist", durationMs: 180000, filePath: "t1.mp3", fileSizeBytes: 100, audioFormat: .mp3)

        // Play track
        playerVM.playTrack(track1)

        // Toggle repeat mode cycle: off -> all -> one -> off
        #expect(playerVM.repeatMode == .off)
        playerVM.cycleRepeatMode()
        #expect(playerVM.repeatMode == .all)
        playerVM.cycleRepeatMode()
        #expect(playerVM.repeatMode == .one)
        playerVM.cycleRepeatMode()
        #expect(playerVM.repeatMode == .off)

        // Toggle shuffle mode
        #expect(playerVM.shuffleMode == .off)
        playerVM.toggleShuffle()
        #expect(playerVM.shuffleMode == .on)
        playerVM.toggleShuffle()
        #expect(playerVM.shuffleMode == .off)

        // Favorite toggle
        #expect(playerVM.isFavorite == false)
        playerVM.toggleFavorite()
        #expect(playerVM.isFavorite == true)
    }

    @Test("HomeViewModel greeting logic")
    func testHomeGreeting() {
        let hVM = HomeViewModel(
            trackRepository: MockTrackRepo(),
            playlistRepository: MockPlaylistRepo(),
            historyRepository: MockHistoryRepo()
        )
        let greeting = hVM.greeting
        #expect(["Good Morning", "Good Afternoon", "Good Evening"].contains(greeting))
    }

    @Test("LibraryViewModel formatting and aggregations")
    func testLibraryViewModelStats() {
        let t1 = Track(id: "1", title: "A", artistName: "Art", durationMs: 60000, filePath: "1.mp3", fileSizeBytes: 1000, audioFormat: .mp3)
        let t2 = Track(id: "2", title: "B", artistName: "Art", durationMs: 120000, filePath: "2.flac", fileSizeBytes: 2000, audioFormat: .flac)

        let lVM = LibraryViewModel(
            trackRepository: MockTrackRepo(tracks: [t1, t2]),
            importService: LibraryImportService(
                storageManager: LocalFileStorageManager(baseStorageURL: URL(fileURLWithPath: NSTemporaryDirectory())),
                trackRepository: MockTrackRepo()
            ),
            filterService: LibraryFilterService(
                trackRepository: MockTrackRepo(),
                storageManager: LocalFileStorageManager(baseStorageURL: URL(fileURLWithPath: NSTemporaryDirectory()))
            )
        )

        lVM.loadLibrary()
        #expect(lVM.totalTracksCount == 2)
        #expect(lVM.totalLibraryDurationFormatted == "3 min")
    }
}

// MARK: - Mocks for ViewModel Tests

private final class MockTrackRepo: TrackRepositoryProtocol, @unchecked Sendable {
    var tracks: [Track]

    init(tracks: [Track] = []) {
        self.tracks = tracks
    }

    func getTrack(byId id: String) throws -> Track? { tracks.first { $0.id == id } }
    func getAllTracks() throws -> [Track] { tracks }
    func getTracks(page: Int, pageSize: Int) throws -> [Track] { tracks }
    func searchTracks(query: String) throws -> [Track] { tracks.filter { $0.title.contains(query) } }
    func getTracksByArtist(name: String) throws -> [Track] { tracks.filter { $0.artistName == name } }
    func getTracksByAlbum(title: String) throws -> [Track] { tracks.filter { $0.albumTitle == title } }
    func getTrackBySpotifyId(_ spotifyId: String) throws -> Track? { nil }
    func getTrackByFileHash(_ fileHash: String) throws -> Track? { nil }
    func getRecentlyAddedTracks(limit: Int) throws -> [Track] { tracks }
    func insertTrack(_ track: Track) throws { tracks.append(track) }
    func insertTracks(_ newTracks: [Track]) throws { tracks.append(contentsOf: newTracks) }
    func updateTrack(_ track: Track) throws {}
    func deleteTrack(byId id: String) throws { tracks.removeAll { $0.id == id } }
    func countTracks() throws -> Int { tracks.count }
}

private final class MockPlaylistRepo: PlaylistRepositoryProtocol, @unchecked Sendable {
    func getPlaylists() throws -> [Playlist] { [] }
    func getPlaylist(byId id: String) throws -> Playlist? { nil }
    func getPlaylistBySpotifyId(_ spotifyPlaylistId: String) throws -> Playlist? { nil }
    func createPlaylist(_ playlist: Playlist) throws {}
    func updatePlaylist(_ playlist: Playlist) throws {}
    func deletePlaylist(byId id: String) throws {}
    func addTrack(trackId: String, toPlaylistId playlistId: String) throws {}
    func insertTrack(trackId: String, intoPlaylistId playlistId: String, atPosition position: Int) throws {}
    func removeTrack(trackId: String, fromPlaylistId playlistId: String) throws {}
    func reorderTrack(inPlaylistId playlistId: String, fromPosition: Int, toPosition: Int) throws {}
    func getTracksForPlaylist(playlistId: String) throws -> [Track] { [] }
}

private final class MockHistoryRepo: PlaybackHistoryRepositoryProtocol, @unchecked Sendable {
    func record(historyEntry: PlaybackHistory) throws {}
    func getRecentHistory(limit: Int) throws -> [PlaybackHistory] { [] }
    func getMostPlayedTrackIds(limit: Int) throws -> [(trackId: String, playCount: Int)] { [] }
    func clearHistory() throws {}
    func purgeHistoryOlderThan(_ date: Date) throws {}
}
