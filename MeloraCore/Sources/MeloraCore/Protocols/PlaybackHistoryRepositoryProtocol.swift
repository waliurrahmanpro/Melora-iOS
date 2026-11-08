import Foundation

/// Repository contract managing playback history logs and listening statistics.
public protocol PlaybackHistoryRepositoryProtocol: Sendable {
    /// Records a new playback event into history.
    func record(historyEntry: PlaybackHistory) throws

    /// Retrieves the most recent playback history entries up to a specified limit.
    func getRecentHistory(limit: Int) throws -> [PlaybackHistory]

    /// Retrieves the most frequently listened track IDs.
    func getMostPlayedTrackIds(limit: Int) throws -> [(trackId: String, playCount: Int)]

    /// Clears all stored playback history.
    func clearHistory() throws

    /// Deletes playback history older than a specified date.
    func purgeHistoryOlderThan(_ date: Date) throws
}
