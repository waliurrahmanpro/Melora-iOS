import Foundation
import Testing
@testable import MeloraCore

@Suite("MeloraCore Model Tests")
struct ModelTests {

    @Test("AudioFormat extension and property validation")
    func testAudioFormats() {
        #expect(AudioFormat(fileExtension: "mp3") == .mp3)
        #expect(AudioFormat(fileExtension: ".FLAC") == .flac)
        #expect(AudioFormat(fileExtension: "m4a") == .m4a)
        #expect(AudioFormat(fileExtension: "wav") == .wav)
        #expect(AudioFormat(fileExtension: "aiff") == .aiff)
        #expect(AudioFormat(fileExtension: "invalid") == nil)

        #expect(AudioFormat.flac.isLossless == true)
        #expect(AudioFormat.alac.isLossless == true)
        #expect(AudioFormat.wav.isLossless == true)
        #expect(AudioFormat.mp3.isLossless == false)
        #expect(AudioFormat.aac.isLossless == false)

        #expect(AudioFormat.mp3.mimeType == "audio/mpeg")
        #expect(AudioFormat.flac.mimeType == "audio/flac")
    }

    @Test("Track formatting and serialization")
    func testTrackProperties() throws {
        let track = Track(
            id: "track-123",
            title: "Midnight City",
            artistName: "M83",
            albumTitle: "Hurry Up, We're Dreaming",
            durationMs: 243000, // 4m 03s
            filePath: "Tracks/midnight-city.flac",
            fileSizeBytes: 28 * 1024 * 1024, // 28 MB
            audioFormat: .flac,
            bitrate: 1411000,
            sampleRate: 44100,
            channels: 2,
            spotifyId: "spotify:track:123"
        )

        #expect(track.durationFormatted == "4:03")
        #expect(track.durationSeconds == 243.0)
        #expect(track.audioFormat == .flac)

        // Codable round-trip
        let encoder = JSONEncoder()
        let data = try encoder.encode(track)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Track.self, from: data)

        #expect(decoded.id == track.id)
        #expect(decoded.title == track.title)
        #expect(decoded.artistName == track.artistName)
        #expect(decoded.durationMs == track.durationMs)
        #expect(decoded.audioFormat == track.audioFormat)
    }

    @Test("PlaybackPosition calculations")
    func testPlaybackPosition() {
        let position = PlaybackPosition(currentTimeSeconds: 60.0, durationSeconds: 240.0)
        #expect(position.progress == 0.25)
        #expect(position.remainingSeconds == 180.0)

        let zeroDuration = PlaybackPosition(currentTimeSeconds: 0, durationSeconds: 0)
        #expect(zeroDuration.progress == 0.0)
        #expect(zeroDuration.remainingSeconds == 0.0)
    }

    @Test("Playlist duration formatting")
    func testPlaylistDuration() {
        let playlist = Playlist(
            id: "pl-1",
            title: "Synthwave Favorites",
            trackCount: 15,
            totalDurationMs: 3600000 + 720000 // 1 hr 12 min
        )
        #expect(playlist.durationFormatted == "1 hr 12 min")

        let shortPlaylist = Playlist(
            id: "pl-2",
            title: "Quick Chill",
            trackCount: 3,
            totalDurationMs: 600000 // 10 min
        )
        #expect(shortPlaylist.durationFormatted == "10 min")
    }

    @Test("PlaybackHistory listening threshold")
    func testPlaybackHistoryThreshold() {
        let partialListen = PlaybackHistory(
            trackId: "track-1",
            durationPlayedMs: 30000,
            completionPercentage: 0.35
        )
        #expect(partialListen.isConsideredListened == false)

        let fullListen = PlaybackHistory(
            trackId: "track-1",
            durationPlayedMs: 200000,
            completionPercentage: 0.85
        )
        #expect(fullListen.isConsideredListened == true)
    }
}
