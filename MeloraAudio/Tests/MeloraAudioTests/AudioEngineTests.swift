import Foundation
import Testing
@testable import MeloraCore
@testable import MeloraData
@testable import MeloraAudio

@Suite("Audio Engine & Queue Tests")
struct AudioEngineTests {

    @Test("QueueManager sequential navigation and bounds")
    func testQueueNavigation() {
        let q = QueueManager()
        let t1 = Track(id: "1", title: "Track 1", artistName: "Artist", durationMs: 180000, filePath: "t1.mp3", fileSizeBytes: 100, audioFormat: .mp3)
        let t2 = Track(id: "2", title: "Track 2", artistName: "Artist", durationMs: 200000, filePath: "t2.mp3", fileSizeBytes: 100, audioFormat: .mp3)
        let t3 = Track(id: "3", title: "Track 3", artistName: "Artist", durationMs: 220000, filePath: "t3.mp3", fileSizeBytes: 100, audioFormat: .mp3)

        q.setQueue(tracks: [t1, t2, t3], startIndex: 0)
        #expect(q.currentTrack?.id == "1")

        // Next track
        #expect(q.nextTrack()?.id == "2")
        #expect(q.nextTrack()?.id == "3")
        #expect(q.nextTrack() == nil) // End of queue with repeat off
    }

    @Test("QueueManager Repeat All and Repeat One modes")
    func testRepeatModes() {
        let q = QueueManager()
        let t1 = Track(id: "1", title: "Track 1", artistName: "Artist", durationMs: 100000, filePath: "t1.mp3", fileSizeBytes: 100, audioFormat: .mp3)
        let t2 = Track(id: "2", title: "Track 2", artistName: "Artist", durationMs: 100000, filePath: "t2.mp3", fileSizeBytes: 100, audioFormat: .mp3)

        q.setQueue(tracks: [t1, t2], startIndex: 1) // Start at t2 (last track)

        // Repeat All: wraps back to index 0
        q.repeatMode = .all
        #expect(q.nextTrack()?.id == "1")

        // Repeat One: stays on current track
        q.repeatMode = .one
        #expect(q.nextTrack()?.id == "1")
        #expect(q.nextTrack()?.id == "1")
    }

    @Test("QueueManager Shuffle preserves active track identity and restores order")
    func testShufflePreservesActiveTrack() {
        let q = QueueManager()
        let tracks = (1...10).map {
            Track(id: "\($0)", title: "Track \($0)", artistName: "Artist", durationMs: 100000, filePath: "t\($0).mp3", fileSizeBytes: 100, audioFormat: .mp3)
        }

        q.setQueue(tracks: tracks, startIndex: 4) // Track 5 selected
        #expect(q.currentTrack?.id == "5")

        // Enable shuffle
        q.setShuffleMode(.on)
        #expect(q.shuffleMode == .on)
        // Current track remains active at index 0
        #expect(q.currentTrack?.id == "5")
        #expect(q.currentIndex == 0)
        #expect(q.queue.count == 10)

        // Disable shuffle: restores original order and locates Track 5
        q.setShuffleMode(.off)
        #expect(q.shuffleMode == .off)
        #expect(q.currentTrack?.id == "5")
        #expect(q.currentIndex == 4)
        #expect(q.queue.map { $0.id } == tracks.map { $0.id })
    }

    @Test("QueueManager previous track threshold")
    func testPreviousTrackThreshold() {
        let q = QueueManager()
        let t1 = Track(id: "1", title: "Track 1", artistName: "Artist", durationMs: 100000, filePath: "t1.mp3", fileSizeBytes: 100, audioFormat: .mp3)
        let t2 = Track(id: "2", title: "Track 2", artistName: "Artist", durationMs: 100000, filePath: "t2.mp3", fileSizeBytes: 100, audioFormat: .mp3)

        q.setQueue(tracks: [t1, t2], startIndex: 1) // On Track 2

        // If played > 3.0 seconds, restart current track
        let (trackRestart, shouldRestart) = q.previousTrack(currentPositionSeconds: 15.0)
        #expect(trackRestart?.id == "2")
        #expect(shouldRestart == true)

        // If played <= 3.0 seconds, go to previous track
        let (trackPrev, prevRestart) = q.previousTrack(currentPositionSeconds: 1.5)
        #expect(trackPrev?.id == "1")
        #expect(prevRestart == false)
    }

    @Test("AudioPlaybackCoordinator interruption and route changes")
    func testCoordinatorInterruptionAndRouteChanges() {
        let mockEngine = MockAudioPlayerEngine()
        let coordinator = AudioPlaybackCoordinator(
            audioEngine: mockEngine,
            configuration: AudioEngineConfiguration(pauseOnHeadphoneDisconnect: true)
        )

        let t1 = Track(id: "1", title: "Song", artistName: "Artist", durationMs: 180000, filePath: "t1.mp3", fileSizeBytes: 100, audioFormat: .mp3)
        mockEngine.activeTrack = t1
        mockEngine.play()
        #expect(mockEngine.status.isPlaying == true)

        // Interruption began (e.g. phone call) -> must pause
        coordinator.audioSessionInterruptionBegan()
        #expect(mockEngine.pauseCallCount == 1)

        // Interruption ended with shouldResume = true -> resumes play
        coordinator.audioSessionInterruptionEnded(shouldResume: true)
        #expect(mockEngine.playCallCount == 2)

        // Headphone disconnected -> must pause
        coordinator.audioSessionHeadphonesDisconnected()
        #expect(mockEngine.pauseCallCount == 2)
    }
}
