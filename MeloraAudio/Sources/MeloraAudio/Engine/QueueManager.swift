import Foundation
import MeloraCore

/// Manages ordered audio track queues, shuffle states, and repeat modes.
public final class QueueManager: @unchecked Sendable {
    private let lock = NSLock()

    private var originalTracks: [Track] = []
    private var activeQueue: [Track] = []
    private var activeIndex: Int = 0

    public var repeatMode: RepeatMode = .off
    public var shuffleMode: ShuffleMode = .off

    public init() {}

    /// The list of tracks currently queued in order of playback.
    public var queue: [Track] {
        lock.lock()
        defer { lock.unlock() }
        return activeQueue
    }

    /// The zero-based index of the currently playing track.
    public var currentIndex: Int {
        lock.lock()
        defer { lock.unlock() }
        return activeIndex
    }

    /// The currently selected track in the queue, if any.
    public var currentTrack: Track? {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < activeQueue.count else { return nil }
        return activeQueue[activeIndex]
    }

    /// Total count of tracks in the active queue.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return activeQueue.count
    }

    /// Sets a new playback queue and initial playback index.
    public func setQueue(tracks: [Track], startIndex: Int = 0) {
        lock.lock()
        defer { lock.unlock() }

        self.originalTracks = tracks
        let safeIndex = min(max(startIndex, 0), max(0, tracks.count - 1))

        if shuffleMode == .on && !tracks.isEmpty {
            // Keep the chosen track first, shuffle the remaining
            var shuffled = tracks
            let selected = shuffled.remove(at: safeIndex)
            shuffled.shuffle()
            shuffled.insert(selected, at: 0)
            self.activeQueue = shuffled
            self.activeIndex = 0
        } else {
            self.activeQueue = tracks
            self.activeIndex = safeIndex
        }
    }

    /// Toggles shuffle mode, preserving the identity of the currently playing track.
    public func setShuffleMode(_ mode: ShuffleMode) {
        lock.lock()
        defer { lock.unlock() }

        guard mode != shuffleMode else { return }
        self.shuffleMode = mode

        guard !activeQueue.isEmpty else { return }

        let current = activeQueue[activeIndex]

        if mode == .on {
            // Enable shuffle: keep current track at index 0, shuffle the rest
            var remaining = originalTracks.filter { $0.id != current.id }
            remaining.shuffle()
            self.activeQueue = [current] + remaining
            self.activeIndex = 0
        } else {
            // Disable shuffle: restore original order and find current track index
            self.activeQueue = originalTracks
            if let restoredIndex = originalTracks.firstIndex(where: { $0.id == current.id }) {
                self.activeIndex = restoredIndex
            } else {
                self.activeIndex = 0
            }
        }
    }

    /// Advances to the next track taking into account RepeatMode.
    ///
    /// - Returns: The next track to play, or nil if queue reached its end.
    public func nextTrack() -> Track? {
        lock.lock()
        defer { lock.unlock() }

        guard !activeQueue.isEmpty else { return nil }

        if repeatMode == .one {
            return activeQueue[activeIndex]
        }

        if activeIndex + 1 < activeQueue.count {
            activeIndex += 1
            return activeQueue[activeIndex]
        } else if repeatMode == .all {
            activeIndex = 0
            return activeQueue[0]
        }

        return nil
    }

    /// Returns the previous track or signals whether the current track should be restarted.
    ///
    /// - Parameter currentPositionSeconds: Current track progress in seconds.
    /// - Returns: Tuple containing the track to play and whether to restart from 0.0.
    public func previousTrack(currentPositionSeconds: Double) -> (track: Track?, restartCurrent: Bool) {
        lock.lock()
        defer { lock.unlock() }

        guard !activeQueue.isEmpty else { return (nil, false) }

        // If played more than 3 seconds, restart current track
        if currentPositionSeconds > 3.0 {
            return (activeQueue[activeIndex], true)
        }

        if activeIndex > 0 {
            activeIndex -= 1
            return (activeQueue[activeIndex], false)
        } else if repeatMode == .all {
            activeIndex = activeQueue.count - 1
            return (activeQueue[activeIndex], false)
        }

        return (activeQueue[activeIndex], true)
    }

    /// Appends a track to the end of both original and active queues.
    public func addTrack(_ track: Track) {
        lock.lock()
        defer { lock.unlock() }
        originalTracks.append(track)
        activeQueue.append(track)
    }

    /// Removes a track at a specific index from the active queue.
    public func removeTrack(at index: Int) {
        lock.lock()
        defer { lock.unlock() }

        guard index >= 0 && index < activeQueue.count else { return }
        let removed = activeQueue.remove(at: index)
        originalTracks.removeAll { $0.id == removed.id }

        if activeIndex >= activeQueue.count {
            activeIndex = max(0, activeQueue.count - 1)
        }
    }

    /// Moves a track from one index to another in the queue.
    public func moveTrack(from sourceIndex: Int, to destinationIndex: Int) {
        lock.lock()
        defer { lock.unlock() }

        guard sourceIndex >= 0 && sourceIndex < activeQueue.count,
              destinationIndex >= 0 && destinationIndex < activeQueue.count,
              sourceIndex != destinationIndex else { return }

        let item = activeQueue.remove(at: sourceIndex)
        activeQueue.insert(item, at: destinationIndex)

        // Adjust activeIndex if the current track was moved
        if activeIndex == sourceIndex {
            activeIndex = destinationIndex
        } else if sourceIndex < activeIndex && destinationIndex >= activeIndex {
            activeIndex -= 1
        } else if sourceIndex > activeIndex && destinationIndex <= activeIndex {
            activeIndex += 1
        }
    }

    /// Clears all tracks from the queue.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        originalTracks.removeAll()
        activeQueue.removeAll()
        activeIndex = 0
    }
}
