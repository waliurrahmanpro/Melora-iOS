import Foundation

/// Configuration settings controlling AVFoundation audio playback and observation.
public struct AudioEngineConfiguration: Sendable, Equatable {
    /// Periodic time observer polling interval in seconds (e.g. 0.25s for 4Hz UI progress updates).
    public let timeObserverInterval: Double

    /// Whether to automatically advance to the next track when the current one finishes.
    public let autoAdvanceOnCompletion: Bool

    /// Minimum listening fraction (0.0 to 1.0) required to count a track as listened in history.
    public let historyCompletionThreshold: Double

    /// Minimum seconds played required to record a history entry (e.g. 30 seconds).
    public let historyMinimumSeconds: Int

    /// Whether to pause playback immediately when headphones or Bluetooth audio devices disconnect.
    public let pauseOnHeadphoneDisconnect: Bool

    public init(
        timeObserverInterval: Double = 0.25,
        autoAdvanceOnCompletion: Bool = true,
        historyCompletionThreshold: Double = 0.70,
        historyMinimumSeconds: Int = 30,
        pauseOnHeadphoneDisconnect: Bool = true
    ) {
        self.timeObserverInterval = timeObserverInterval
        self.autoAdvanceOnCompletion = autoAdvanceOnCompletion
        self.historyCompletionThreshold = historyCompletionThreshold
        self.historyMinimumSeconds = historyMinimumSeconds
        self.pauseOnHeadphoneDisconnect = pauseOnHeadphoneDisconnect
    }

    public static let `default` = AudioEngineConfiguration()
}
