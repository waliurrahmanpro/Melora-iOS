import Foundation
import MeloraCore

/// Concrete implementation of PlaylistRepositoryProtocol backed by SQLite.
public final class SQLitePlaylistRepository: PlaylistRepositoryProtocol, @unchecked Sendable {
    private let database: DatabaseServiceProtocol

    public init(database: DatabaseServiceProtocol) {
        self.database = database
    }

    public func getPlaylists() throws -> [Playlist] {
        let sql = """
        SELECT p.id, p.title, p.description, p.artwork_path, p.is_imported_from_spotify,
               p.spotify_playlist_id, p.created_at, p.updated_at,
               COUNT(pt.track_id) AS track_count,
               COALESCE(SUM(t.duration_ms), 0) AS total_duration_ms
        FROM playlists p
        LEFT JOIN playlist_tracks pt ON p.id = pt.playlist_id
        LEFT JOIN tracks t ON pt.track_id = t.id
        GROUP BY p.id
        ORDER BY p.title COLLATE NOCASE ASC;
        """
        let rows = try database.query(sql: sql, parameters: [])
        return rows.compactMap { parsePlaylist(from: $0) }
    }

    public func getPlaylist(byId id: String) throws -> Playlist? {
        let sql = """
        SELECT p.id, p.title, p.description, p.artwork_path, p.is_imported_from_spotify,
               p.spotify_playlist_id, p.created_at, p.updated_at,
               COUNT(pt.track_id) AS track_count,
               COALESCE(SUM(t.duration_ms), 0) AS total_duration_ms
        FROM playlists p
        LEFT JOIN playlist_tracks pt ON p.id = pt.playlist_id
        LEFT JOIN tracks t ON pt.track_id = t.id
        WHERE p.id = ?
        GROUP BY p.id
        LIMIT 1;
        """
        let rows = try database.query(sql: sql, parameters: [.text(id)])
        guard let row = rows.first else { return nil }
        return parsePlaylist(from: row)
    }

    public func getPlaylistBySpotifyId(_ spotifyPlaylistId: String) throws -> Playlist? {
        let sql = """
        SELECT p.id, p.title, p.description, p.artwork_path, p.is_imported_from_spotify,
               p.spotify_playlist_id, p.created_at, p.updated_at,
               COUNT(pt.track_id) AS track_count,
               COALESCE(SUM(t.duration_ms), 0) AS total_duration_ms
        FROM playlists p
        LEFT JOIN playlist_tracks pt ON p.id = pt.playlist_id
        LEFT JOIN tracks t ON pt.track_id = t.id
        WHERE p.spotify_playlist_id = ?
        GROUP BY p.id
        LIMIT 1;
        """
        let rows = try database.query(sql: sql, parameters: [.text(spotifyPlaylistId)])
        guard let row = rows.first else { return nil }
        return parsePlaylist(from: row)
    }

    public func createPlaylist(_ playlist: Playlist) throws {
        let sql = """
        INSERT INTO playlists (
            id, title, description, artwork_path, is_imported_from_spotify,
            spotify_playlist_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        let params: [SQLValue] = [
            .text(playlist.id),
            .text(playlist.title),
            playlist.description != nil ? .text(playlist.description!) : .null,
            playlist.artworkPath != nil ? .text(playlist.artworkPath!) : .null,
            .integer(playlist.isImportedFromSpotify ? 1 : 0),
            playlist.spotifyPlaylistId != nil ? .text(playlist.spotifyPlaylistId!) : .null,
            .integer(Int64(playlist.createdAt.timeIntervalSince1970)),
            .integer(Int64(playlist.updatedAt.timeIntervalSince1970))
        ]
        try database.execute(sql: sql, parameters: params)
    }

    public func updatePlaylist(_ playlist: Playlist) throws {
        let sql = """
        UPDATE playlists SET
            title = ?,
            description = ?,
            artwork_path = ?,
            updated_at = ?
        WHERE id = ?;
        """
        let nowTimestamp = Int64(Date().timeIntervalSince1970)
        let params: [SQLValue] = [
            .text(playlist.title),
            playlist.description != nil ? .text(playlist.description!) : .null,
            playlist.artworkPath != nil ? .text(playlist.artworkPath!) : .null,
            .integer(nowTimestamp),
            .text(playlist.id)
        ]
        try database.execute(sql: sql, parameters: params)
    }

    public func deletePlaylist(byId id: String) throws {
        let sql = "DELETE FROM playlists WHERE id = ?;"
        try database.execute(sql: sql, parameters: [.text(id)])
    }

    public func addTrack(trackId: String, toPlaylistId playlistId: String) throws {
        try database.transaction {
            let maxPosSql = "SELECT COALESCE(MAX(position), -1) AS max_pos FROM playlist_tracks WHERE playlist_id = ?;"
            let rows = try database.query(sql: maxPosSql, parameters: [.text(playlistId)])
            var nextPos: Int64 = 0
            if let row = rows.first, let maxVal = row["max_pos"], case .integer(let m) = maxVal {
                nextPos = m + 1
            }

            let insertSql = """
            INSERT INTO playlist_tracks (playlist_id, track_id, position, added_at)
            VALUES (?, ?, ?, ?);
            """
            let nowTimestamp = Int64(Date().timeIntervalSince1970)
            try database.execute(sql: insertSql, parameters: [
                .text(playlistId),
                .text(trackId),
                .integer(nextPos),
                .integer(nowTimestamp)
            ])
        }
    }

    public func insertTrack(trackId: String, intoPlaylistId playlistId: String, atPosition position: Int) throws {
        try database.transaction {
            let shiftSql = """
            UPDATE playlist_tracks
            SET position = position + 1
            WHERE playlist_id = ? AND position >= ?;
            """
            try database.execute(sql: shiftSql, parameters: [
                .text(playlistId),
                .integer(Int64(position))
            ])

            let insertSql = """
            INSERT INTO playlist_tracks (playlist_id, track_id, position, added_at)
            VALUES (?, ?, ?, ?);
            """
            let nowTimestamp = Int64(Date().timeIntervalSince1970)
            try database.execute(sql: insertSql, parameters: [
                .text(playlistId),
                .text(trackId),
                .integer(Int64(position)),
                .integer(nowTimestamp)
            ])
        }
    }

    public func removeTrack(trackId: String, fromPlaylistId playlistId: String) throws {
        try database.transaction {
            let posSql = "SELECT position FROM playlist_tracks WHERE playlist_id = ? AND track_id = ? LIMIT 1;"
            let rows = try database.query(sql: posSql, parameters: [.text(playlistId), .text(trackId)])
            guard let row = rows.first, let posVal = row["position"], case .integer(let removedPos) = posVal else {
                return
            }

            let deleteSql = "DELETE FROM playlist_tracks WHERE playlist_id = ? AND track_id = ?;"
            try database.execute(sql: deleteSql, parameters: [.text(playlistId), .text(trackId)])

            let compactSql = """
            UPDATE playlist_tracks
            SET position = position - 1
            WHERE playlist_id = ? AND position > ?;
            """
            try database.execute(sql: compactSql, parameters: [
                .text(playlistId),
                .integer(removedPos)
            ])
        }
    }

    public func reorderTrack(inPlaylistId playlistId: String, fromPosition: Int, toPosition: Int) throws {
        guard fromPosition != toPosition else { return }

        try database.transaction {
            let tempPos: Int64 = -999
            let setTempSql = "UPDATE playlist_tracks SET position = ? WHERE playlist_id = ? AND position = ?;"
            try database.execute(sql: setTempSql, parameters: [
                .integer(tempPos),
                .text(playlistId),
                .integer(Int64(fromPosition))
            ])

            if fromPosition < toPosition {
                let shiftDownSql = """
                UPDATE playlist_tracks
                SET position = position - 1
                WHERE playlist_id = ? AND position > ? AND position <= ?;
                """
                try database.execute(sql: shiftDownSql, parameters: [
                    .text(playlistId),
                    .integer(Int64(fromPosition)),
                    .integer(Int64(toPosition))
                ])
            } else {
                let shiftUpSql = """
                UPDATE playlist_tracks
                SET position = position + 1
                WHERE playlist_id = ? AND position >= ? AND position < ?;
                """
                try database.execute(sql: shiftUpSql, parameters: [
                    .text(playlistId),
                    .integer(Int64(toPosition)),
                    .integer(Int64(fromPosition))
                ])
            }

            let placeSql = "UPDATE playlist_tracks SET position = ? WHERE playlist_id = ? AND position = ?;"
            try database.execute(sql: placeSql, parameters: [
                .integer(Int64(toPosition)),
                .text(playlistId),
                .integer(tempPos)
            ])
        }
    }

    public func getTracksForPlaylist(playlistId: String) throws -> [Track] {
        let sql = """
        SELECT t.id, t.title, t.artist_name, t.album_title, t.duration_ms, t.file_path, t.file_size_bytes,
               t.audio_format, t.bitrate, t.sample_rate, t.channels, t.spotify_id, t.artwork_path,
               t.created_at, t.updated_at
        FROM playlist_tracks pt
        JOIN tracks t ON pt.track_id = t.id
        WHERE pt.playlist_id = ?
        ORDER BY pt.position ASC;
        """
        let rows = try database.query(sql: sql, parameters: [.text(playlistId)])
        return rows.compactMap { parseTrack(from: $0) }
    }

    // MARK: - Parsing Helpers

    private func parsePlaylist(from row: SQLRow) -> Playlist? {
        guard
            let idVal = row["id"], case .text(let id) = idVal,
            let titleVal = row["title"], case .text(let title) = titleVal,
            let createdVal = row["created_at"], case .integer(let createdAtSec) = createdVal,
            let updatedVal = row["updated_at"], case .integer(let updatedAtSec) = updatedVal
        else {
            return nil
        }

        var description: String? = nil
        if let descVal = row["description"], case .text(let desc) = descVal {
            description = desc
        }

        var artworkPath: String? = nil
        if let artVal = row["artwork_path"], case .text(let art) = artVal {
            artworkPath = art
        }

        var isImported = false
        if let impVal = row["is_imported_from_spotify"], case .integer(let imp) = impVal {
            isImported = imp == 1
        }

        var spotifyPlaylistId: String? = nil
        if let sIdVal = row["spotify_playlist_id"], case .text(let sId) = sIdVal {
            spotifyPlaylistId = sId
        }

        var trackCount = 0
        if let countVal = row["track_count"], case .integer(let c) = countVal {
            trackCount = Int(c)
        }

        var totalDuration = 0
        if let durVal = row["total_duration_ms"], case .integer(let d) = durVal {
            totalDuration = Int(d)
        }

        return Playlist(
            id: id,
            title: title,
            description: description,
            artworkPath: artworkPath,
            isImportedFromSpotify: isImported,
            spotifyPlaylistId: spotifyPlaylistId,
            trackCount: trackCount,
            totalDurationMs: totalDuration,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtSec)),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(updatedAtSec))
        )
    }

    private func parseTrack(from row: SQLRow) -> Track? {
        guard
            let idVal = row["id"], case .text(let id) = idVal,
            let titleVal = row["title"], case .text(let title) = titleVal,
            let artistVal = row["artist_name"], case .text(let artist) = artistVal,
            let durVal = row["duration_ms"], case .integer(let durationMs) = durVal,
            let pathVal = row["file_path"], case .text(let filePath) = pathVal,
            let sizeVal = row["file_size_bytes"], case .integer(let fileSizeBytes) = sizeVal,
            let fmtVal = row["audio_format"], case .text(let formatStr) = fmtVal,
            let format = AudioFormat(rawValue: formatStr),
            let createdVal = row["created_at"], case .integer(let createdAtSec) = createdVal,
            let updatedVal = row["updated_at"], case .integer(let updatedAtSec) = updatedVal
        else {
            return nil
        }

        var albumTitle: String? = nil
        if let albumVal = row["album_title"], case .text(let album) = albumVal {
            albumTitle = album
        }

        var bitrate: Int? = nil
        if let bitVal = row["bitrate"], case .integer(let bit) = bitVal {
            bitrate = Int(bit)
        }

        var sampleRate: Int? = nil
        if let sampleVal = row["sample_rate"], case .integer(let sample) = sampleVal {
            sampleRate = Int(sample)
        }

        var channels: Int = 2
        if let chVal = row["channels"], case .integer(let ch) = chVal {
            channels = Int(ch)
        }

        var spotifyId: String? = nil
        if let spotVal = row["spotify_id"], case .text(let sId) = spotVal {
            spotifyId = sId
        }

        var artworkPath: String? = nil
        if let artVal = row["artwork_path"], case .text(let art) = artVal {
            artworkPath = art
        }

        return Track(
            id: id,
            title: title,
            artistName: artist,
            albumTitle: albumTitle,
            durationMs: Int(durationMs),
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            audioFormat: format,
            bitrate: bitrate,
            sampleRate: sampleRate,
            channels: channels,
            spotifyId: spotifyId,
            artworkPath: artworkPath,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtSec)),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(updatedAtSec))
        )
    }
}
