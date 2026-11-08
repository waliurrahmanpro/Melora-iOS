import Foundation

/// Delegate/observer protocol to receive continuous playback events from the audio engine.
public protocol AudioPlayerEngineObserver: AnyObject, Sendable {
    func audioEngineDidChangeStatus(_ status: PlaybackStatus)
    func audioEngineDidChangePosition(_ position: PlaybackPosition)
    func audioEngineDidFinishPlaying(track: Track)
}

/// Abstract contract for the platform audio playback engine.
///
/// Implementations on iOS wrap `AVFoundation` (`AVQueuePlayer` and `AVAudioSession`).
/// On other platforms or during unit testing, mock implementations can simulate audio playback.
public protocol AudioPlayerEngineProtocol: AnyObject, Sendable {
    /// Currently loaded track.
    var currentTrack: Track? { get }

    /// Current playback status.
    var status: PlaybackStatus { get }

    /// Current playback position and duration.
    var position: PlaybackPosition { get }

    /// Master volume level between 0.0 and 1.0.
    var volume: Float { get set }

    /// Repeat mode for playlist progression.
    var repeatMode: RepeatMode { get set }

    /// Shuffle mode for queue randomisation.
    var shuffleMode: ShuffleMode { get set }

    /// Register an observer to receive status and progress updates.
    func addObserver(_ observer: AudioPlayerEngineObserver)

    /// Unregister a previously registered observer.
    func removeObserver(_ observer: AudioPlayerEngineObserver)

    /// Loads and prepares an audio track for playback from sandboxed local storage.
    func load(track: Track, autoPlay: Bool) async throws

    /// Starts or resumes audio playback.
    func play()

    /// Pauses current audio playback.
    func pause()

    /// Toggles between playing and paused states.
    func togglePlayPause()

    /// Halts playback and resets time coordinates.
    func stop()

    /// Seeks playback to a target time offset in seconds.
    func seek(toSeconds seconds: Double) async

    /// Queues a collection of tracks for sequential playback.
    func setQueue(tracks: [Track], startIndex: Int) async throws

    /// Skips to the next track in the queue.
    func skipToNext() async

    /// Skips to the previous track in the queue or restarts the current track.
    func skipToPrevious() async
}
