import Foundation
import MeloraCore

/// Concrete implementation of PlaybackHistoryRepositoryProtocol backed by SQLite.
public final class SQLitePlaybackHistoryRepository: PlaybackHistoryRepositoryProtocol, @unchecked Sendable {
    private let database: DatabaseServiceProtocol

    public init(database: DatabaseServiceProtocol) {
        self.database = database
    }

    public func record(historyEntry: PlaybackHistory) throws {
        let sql = """
        INSERT INTO playback_history (
            track_id, played_at, duration_played_ms, completion_percentage
        ) VALUES (?, ?, ?, ?);
        """
        let params: [SQLValue] = [
            .text(historyEntry.trackId),
            .integer(Int64(historyEntry.playedAt.timeIntervalSince1970)),
            .integer(Int64(historyEntry.durationPlayedMs)),
            .real(historyEntry.completionPercentage)
        ]
        try database.execute(sql: sql, parameters: params)
    }

    public func getRecentHistory(limit: Int) throws -> [PlaybackHistory] {
        let safeLimit = max(1, limit)
        let sql = """
        SELECT h.id, h.track_id, h.played_at, h.duration_played_ms, h.completion_percentage,
               t.id as t_id, t.title, t.artist_name, t.album_title, t.duration_ms, t.file_path,
               t.file_size_bytes, t.audio_format, t.bitrate, t.sample_rate, t.channels,
               t.spotify_id, t.artwork_path, t.created_at, t.updated_at
        FROM playback_history h
        LEFT JOIN tracks t ON h.track_id = t.id
        ORDER BY h.played_at DESC
        LIMIT ?;
        """
        let rows = try database.query(sql: sql, parameters: [.integer(Int64(safeLimit))])
        return rows.compactMap { parseHistory(from: $0) }
    }

    public func getMostPlayedTrackIds(limit: Int) throws -> [(trackId: String, playCount: Int)] {
        let safeLimit = max(1, limit)
        let sql = """
        SELECT track_id, COUNT(*) AS play_count
        FROM playback_history
        GROUP BY track_id
        ORDER BY play_count DESC
        LIMIT ?;
        """
        let rows = try database.query(sql: sql, parameters: [.integer(Int64(safeLimit))])
        var results: [(trackId: String, playCount: Int)] = []
        for row in rows {
            if let idVal = row["track_id"], case .text(let id) = idVal,
               let countVal = row["play_count"], case .integer(let count) = countVal {
                results.append((trackId: id, playCount: Int(count)))
            }
        }
        return results
    }

    public func clearHistory() throws {
        let sql = "DELETE FROM playback_history;"
        try database.execute(sql: sql, parameters: [])
    }

    public func purgeHistoryOlderThan(_ date: Date) throws {
        let sql = "DELETE FROM playback_history WHERE played_at < ?;"
        let timestamp = Int64(date.timeIntervalSince1970)
        try database.execute(sql: sql, parameters: [.integer(timestamp)])
    }

    // MARK: - Parsing Helpers

    private func parseHistory(from row: SQLRow) -> PlaybackHistory? {
        guard
            let idVal = row["id"], case .integer(let id) = idVal,
            let trackIdVal = row["track_id"], case .text(let trackId) = trackIdVal,
            let playedVal = row["played_at"], case .integer(let playedAtSec) = playedVal,
            let durVal = row["duration_played_ms"], case .integer(let durMs) = durVal,
            let compVal = row["completion_percentage"], case .real(let comp) = compVal
        else {
            return nil
        }

        var track: Track? = nil
        if let tIdVal = row["t_id"], case .text(let tId) = tIdVal,
           let titleVal = row["title"], case .text(let title) = titleVal,
           let artistVal = row["artist_name"], case .text(let artist) = artistVal,
           let tDurVal = row["duration_ms"], case .integer(let tDur) = tDurVal,
           let pathVal = row["file_path"], case .text(let path) = pathVal,
           let sizeVal = row["file_size_bytes"], case .integer(let size) = sizeVal,
           let fmtVal = row["audio_format"], case .text(let fmtStr) = fmtVal,
           let format = AudioFormat(rawValue: fmtStr),
           let createdVal = row["created_at"], case .integer(let cSec) = createdVal,
           let updatedVal = row["updated_at"], case .integer(let uSec) = updatedVal {

            var album: String? = nil
            if let aVal = row["album_title"], case .text(let a) = aVal { album = a }

            var bitrate: Int? = nil
            if let bVal = row["bitrate"], case .integer(let b) = bVal { bitrate = Int(b) }

            var sampleRate: Int? = nil
            if let sVal = row["sample_rate"], case .integer(let s) = sVal { sampleRate = Int(s) }

            var channels = 2
            if let chVal = row["channels"], case .integer(let ch) = chVal { channels = Int(ch) }

            var spotifyId: String? = nil
            if let spVal = row["spotify_id"], case .text(let sp) = spVal { spotifyId = sp }

            var artworkPath: String? = nil
            if let artVal = row["artwork_path"], case .text(let art) = artVal { artworkPath = art }

            track = Track(
                id: tId,
                title: title,
                artistName: artist,
                albumTitle: album,
                durationMs: Int(tDur),
                filePath: path,
                fileSizeBytes: size,
                audioFormat: format,
                bitrate: bitrate,
                sampleRate: sampleRate,
                channels: channels,
                spotifyId: spotifyId,
                artworkPath: artworkPath,
                createdAt: Date(timeIntervalSince1970: TimeInterval(cSec)),
                updatedAt: Date(timeIntervalSince1970: TimeInterval(uSec))
            )
        }

        return PlaybackHistory(
            id: id,
            trackId: trackId,
            track: track,
            playedAt: Date(timeIntervalSince1970: TimeInterval(playedAtSec)),
            durationPlayedMs: Int(durMs),
            completionPercentage: comp
        )
    }
}
