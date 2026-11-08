import Foundation
import MeloraCore

/// Concrete implementation of TrackRepositoryProtocol backed by SQLite.
public final class SQLiteTrackRepository: TrackRepositoryProtocol, @unchecked Sendable {
    private let database: DatabaseServiceProtocol

    public init(database: DatabaseServiceProtocol) {
        self.database = database
    }

    public func getTrack(byId id: String) throws -> Track? {
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks WHERE id = ? LIMIT 1;
        """
        let rows = try database.query(sql: sql, parameters: [.text(id)])
        guard let row = rows.first else { return nil }
        return parseTrack(from: row)
    }

    public func getAllTracks() throws -> [Track] {
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        ORDER BY title COLLATE NOCASE ASC;
        """
        let rows = try database.query(sql: sql, parameters: [])
        return rows.compactMap { parseTrack(from: $0) }
    }

    public func getTracks(page: Int, pageSize: Int) throws -> [Track] {
        let safePage = max(0, page)
        let safePageSize = max(1, pageSize)
        let offset = safePage * safePageSize

        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        ORDER BY title COLLATE NOCASE ASC
        LIMIT ? OFFSET ?;
        """
        let rows = try database.query(sql: sql, parameters: [
            .integer(Int64(safePageSize)),
            .integer(Int64(offset))
        ])
        return rows.compactMap { parseTrack(from: $0) }
    }

    public func searchTracks(query: String) throws -> [Track] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let wildcard = "%\(trimmed)%"
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        WHERE title LIKE ? OR artist_name LIKE ? OR album_title LIKE ?
        ORDER BY title COLLATE NOCASE ASC
        LIMIT 50;
        """
        let rows = try database.query(sql: sql, parameters: [
            .text(wildcard),
            .text(wildcard),
            .text(wildcard)
        ])
        return rows.compactMap { parseTrack(from: $0) }
    }

    public func getTracksByArtist(name: String) throws -> [Track] {
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        WHERE artist_name = ? COLLATE NOCASE
        ORDER BY album_title COLLATE NOCASE ASC, title COLLATE NOCASE ASC;
        """
        let rows = try database.query(sql: sql, parameters: [.text(name)])
        return rows.compactMap { parseTrack(from: $0) }
    }

    public func getTracksByAlbum(title: String) throws -> [Track] {
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        WHERE album_title = ? COLLATE NOCASE
        ORDER BY title COLLATE NOCASE ASC;
        """
        let rows = try database.query(sql: sql, parameters: [.text(title)])
        return rows.compactMap { parseTrack(from: $0) }
    }

    public func getTrackBySpotifyId(_ spotifyId: String) throws -> Track? {
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        WHERE spotify_id = ?
        LIMIT 1;
        """
        let rows = try database.query(sql: sql, parameters: [.text(spotifyId)])
        guard let row = rows.first else { return nil }
        return parseTrack(from: row)
    }

    public func getTrackByFileHash(_ fileHash: String) throws -> Track? {
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        WHERE file_hash = ?
        LIMIT 1;
        """
        let rows = try database.query(sql: sql, parameters: [.text(fileHash)])
        guard let row = rows.first else { return nil }
        return parseTrack(from: row)
    }

    public func getRecentlyAddedTracks(limit: Int = 20) throws -> [Track] {
        let safeLimit = max(1, limit)
        let sql = """
        SELECT id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
               audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        FROM tracks
        ORDER BY created_at DESC
        LIMIT ?;
        """
        let rows = try database.query(sql: sql, parameters: [.integer(Int64(safeLimit))])
        return rows.compactMap { parseTrack(from: $0) }
    }

    public func insertTrack(_ track: Track) throws {
        let sql = """
        INSERT INTO tracks (
            id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
            audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        try database.execute(sql: sql, parameters: serializeTrack(track))
    }

    public func insertTracks(_ tracks: [Track]) throws {
        let sql = """
        INSERT INTO tracks (
            id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
            audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, file_hash, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        try database.transaction {
            for track in tracks {
                try database.execute(sql: sql, parameters: serializeTrack(track))
            }
        }
    }

    public func updateTrack(_ track: Track) throws {
        let sql = """
        UPDATE tracks SET
            title = ?,
            artist_name = ?,
            album_title = ?,
            duration_ms = ?,
            file_path = ?,
            file_size_bytes = ?,
            audio_format = ?,
            bitrate = ?,
            sample_rate = ?,
            channels = ?,
            spotify_id = ?,
            artwork_path = ?,
            file_hash = ?,
            updated_at = ?
        WHERE id = ?;
        """
        let nowTimestamp = Int64(Date().timeIntervalSince1970)
        let params: [SQLValue] = [
            .text(track.title),
            .text(track.artistName),
            track.albumTitle != nil ? .text(track.albumTitle!) : .null,
            .integer(Int64(track.durationMs)),
            .text(track.filePath),
            .integer(track.fileSizeBytes),
            .text(track.audioFormat.rawValue),
            track.bitrate != nil ? .integer(Int64(track.bitrate!)) : .null,
            track.sampleRate != nil ? .integer(Int64(track.sampleRate!)) : .null,
            .integer(Int64(track.channels)),
            track.spotifyId != nil ? .text(track.spotifyId!) : .null,
            track.artworkPath != nil ? .text(track.artworkPath!) : .null,
            track.fileHash != nil ? .text(track.fileHash!) : .null,
            .integer(nowTimestamp),
            .text(track.id)
        ]
        try database.execute(sql: sql, parameters: params)
    }

    public func deleteTrack(byId id: String) throws {
        let sql = "DELETE FROM tracks WHERE id = ?;"
        try database.execute(sql: sql, parameters: [.text(id)])
    }

    public func countTracks() throws -> Int {
        let sql = "SELECT COUNT(*) as count FROM tracks;"
        let rows = try database.query(sql: sql, parameters: [])
        if let row = rows.first, let countVal = row["count"] {
            if case .integer(let count) = countVal {
                return Int(count)
            }
        }
        return 0
    }

    // MARK: - Serialization Helpers

    private func serializeTrack(_ track: Track) -> [SQLValue] {
        return [
            .text(track.id),
            .text(track.title),
            .text(track.artistName),
            track.albumTitle != nil ? .text(track.albumTitle!) : .null,
            .integer(Int64(track.durationMs)),
            .text(track.filePath),
            .integer(track.fileSizeBytes),
            .text(track.audioFormat.rawValue),
            track.bitrate != nil ? .integer(Int64(track.bitrate!)) : .null,
            track.sampleRate != nil ? .integer(Int64(track.sampleRate!)) : .null,
            .integer(Int64(track.channels)),
            track.spotifyId != nil ? .text(track.spotifyId!) : .null,
            track.artworkPath != nil ? .text(track.artworkPath!) : .null,
            track.fileHash != nil ? .text(track.fileHash!) : .null,
            .integer(Int64(track.createdAt.timeIntervalSince1970)),
            .integer(Int64(track.updatedAt.timeIntervalSince1970))
        ]
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

        var fileHash: String? = nil
        if let hashVal = row["file_hash"], case .text(let h) = hashVal {
            fileHash = h
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
            fileHash: fileHash,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtSec)),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(updatedAtSec))
        )
    }
}
