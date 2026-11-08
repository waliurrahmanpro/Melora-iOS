import Foundation

/// Domain model capturing a completed or partial audio playback session.
public struct PlaybackHistory: Identifiable, Hashable, Codable, Sendable {
    /// Auto-incrementing database primary key.
    public let id: Int64?

    /// ID of the track that was played.
    public let trackId: String

    /// Optional hydrated track object.
    public let track: Track?

    /// Timestamp when the playback session took place.
    public let playedAt: Date

    /// Number of milliseconds the audio was actively played.
    public let durationPlayedMs: Int

    /// Fraction of track played from 0.0 to 1.0 (e.g. 0.95 for 95% completion).
    public let completionPercentage: Double

    public init(
        id: Int64? = nil,
        trackId: String,
        track: Track? = nil,
        playedAt: Date = Date(),
        durationPlayedMs: Int,
        completionPercentage: Double
    ) {
        self.id = id
        self.trackId = trackId
        self.track = track
        self.playedAt = playedAt
        self.durationPlayedMs = durationPlayedMs
        self.completionPercentage = min(max(completionPercentage, 0.0), 1.0)
    }

    /// Indicates whether the track was played sufficiently to count as a full listen (> 70%).
    public var isConsideredListened: Bool {
        return completionPercentage >= 0.70
    }
}
