import Foundation
import Testing
@testable import MeloraCore
@testable import MeloraData

@Suite("Storage & File Ingestion Tests")
struct StorageManagerTests {

    @Test("FileValidator detects valid and invalid audio extensions")
    func testExtensionValidation() throws {
        let flacURL = URL(fileURLWithPath: "/music/track.flac")
        let mp3URL = URL(fileURLWithPath: "/music/song.MP3")
        let wavURL = URL(fileURLWithPath: "/music/recording.wav")
        let invalidURL = URL(fileURLWithPath: "/music/file.exe")

        #expect(try FileValidator.validateExtension(of: flacURL) == .flac)
        #expect(try FileValidator.validateExtension(of: mp3URL) == .mp3)
        #expect(try FileValidator.validateExtension(of: wavURL) == .wav)

        #expect(throws: StorageError.self) {
            try FileValidator.validateExtension(of: invalidURL)
        }
    }

    @Test("FileValidator sanitizes paths and prevents path traversal")
    func testPathTraversalPrevention() throws {
        let validPath = "Tracks/valid_track_123.flac"
        #expect(try FileValidator.sanitizeRelativePath(validPath) == "Tracks/valid_track_123.flac")

        // Traversal attempts
        #expect(throws: StorageError.self) {
            try FileValidator.sanitizeRelativePath("../secret/passwords.txt")
        }
        #expect(throws: StorageError.self) {
            try FileValidator.sanitizeRelativePath("Tracks/../../System")
        }
    }

    @Test("LibraryFilterService sorting and filtering")
    func testFilterAndSorting() {
        let track1 = Track(
            id: "t1",
            title: "Aerodynamic",
            artistName: "Daft Punk",
            albumTitle: "Discovery",
            durationMs: 210000,
            filePath: "Tracks/t1.flac",
            fileSizeBytes: 20000000,
            audioFormat: .flac,
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        let track2 = Track(
            id: "t2",
            title: "Digital Love",
            artistName: "Daft Punk",
            albumTitle: "Discovery",
            durationMs: 300000,
            filePath: "Tracks/t2.mp3",
            fileSizeBytes: 8000000,
            audioFormat: .mp3,
            createdAt: Date(timeIntervalSince1970: 2000)
        )
        let track3 = Track(
            id: "t3",
            title: "Midnight City",
            artistName: "M83",
            albumTitle: "Hurry Up",
            durationMs: 240000,
            filePath: "Tracks/t3.wav",
            fileSizeBytes: 30000000,
            audioFormat: .wav,
            createdAt: Date(timeIntervalSince1970: 3000)
        )

        let tracks = [track2, track1, track3]

        // Create mock repository & storage manager
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MeloraTest_\(UUID().uuidString)")
        let storage = LocalFileStorageManager(baseStorageURL: tempDir)
        let filterService = LibraryFilterService(
            trackRepository: MockTrackRepository(),
            storageManager: storage
        )

        // Filter by artist
        let daftPunkTracks = filterService.filterTracks(tracks: tracks, artistName: "Daft Punk")
        #expect(daftPunkTracks.count == 2)

        // Filter by format
        let flacTracks = filterService.filterTracks(tracks: tracks, audioFormat: .flac)
        #expect(flacTracks.count == 1)
        #expect(flacTracks.first?.id == "t1")

        // Sort by title ascending
        let sortedByTitle = filterService.sortTracks(tracks, by: .titleAscending)
        #expect(sortedByTitle.first?.title == "Aerodynamic")
        #expect(sortedByTitle.last?.title == "Midnight City")

        // Sort by duration shortest
        let sortedByDuration = filterService.sortTracks(tracks, by: .durationShortest)
        #expect(sortedByDuration.first?.id == "t1") // 210000 ms
        #expect(sortedByDuration.last?.id == "t2")  // 300000 ms

        // Clean up temp dir
        try? FileManager.default.removeItem(at: tempDir)
    }
}

// Simple test mock for repository
private final class MockTrackRepository: TrackRepositoryProtocol, @unchecked Sendable {
    func getTrack(byId id: String) throws -> Track? { return nil }
    func getAllTracks() throws -> [Track] { return [] }
    func getTracks(page: Int, pageSize: Int) throws -> [Track] { return [] }
    func searchTracks(query: String) throws -> [Track] { return [] }
    func getTracksByArtist(name: String) throws -> [Track] { return [] }
    func getTracksByAlbum(title: String) throws -> [Track] { return [] }
    func getTrackBySpotifyId(_ spotifyId: String) throws -> Track? { return nil }
    func getTrackByFileHash(_ fileHash: String) throws -> Track? { return nil }
    func getRecentlyAddedTracks(limit: Int) throws -> [Track] { return [] }
    func insertTrack(_ track: Track) throws {}
    func insertTracks(_ tracks: [Track]) throws {}
    func updateTrack(_ track: Track) throws {}
    func deleteTrack(byId id: String) throws {}
    func countTracks() throws -> Int { return 0 }
}
