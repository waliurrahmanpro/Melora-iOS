import Foundation

/// Canonical DDL definitions and versioned migrations for the Melora SQLite database.
public enum SQLiteSchema {
    /// Current schema version stored in SQLite `user_version`.
    public static let currentVersion: Int = 1

    /// Initial setup pragmas to enforce foreign key integrity and WAL journaling mode.
    public static let pragmas: [String] = [
        "PRAGMA foreign_keys = ON;",
        "PRAGMA journal_mode = WAL;",
        "PRAGMA synchronous = NORMAL;"
    ]

    /// DDL statements for Version 1.
    public static let version1Statements: [String] = [
        """
        CREATE TABLE IF NOT EXISTS tracks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist_name TEXT NOT NULL,
            album_title TEXT,
            duration_ms INTEGER NOT NULL,
            file_path TEXT NOT NULL,
            file_size_bytes INTEGER NOT NULL,
            audio_format TEXT NOT NULL,
            bitrate INTEGER,
            sample_rate INTEGER,
            channels INTEGER DEFAULT 2,
            spotify_id TEXT UNIQUE,
            artwork_path TEXT,
            file_hash TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS artists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            spotify_id TEXT UNIQUE,
            artwork_url TEXT
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS albums (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist_id TEXT,
            release_year INTEGER,
            artwork_path TEXT,
            spotify_id TEXT UNIQUE,
            FOREIGN KEY(artist_id) REFERENCES artists(id) ON DELETE SET NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS playlists (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            artwork_path TEXT,
            is_imported_from_spotify INTEGER DEFAULT 0,
            spotify_playlist_id TEXT UNIQUE,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS playlist_tracks (
            playlist_id TEXT NOT NULL,
            track_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            added_at INTEGER NOT NULL,
            PRIMARY KEY(playlist_id, track_id),
            FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
            FOREIGN KEY(track_id) REFERENCES tracks(id) ON DELETE CASCADE
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS playback_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            track_id TEXT NOT NULL,
            played_at INTEGER NOT NULL,
            duration_played_ms INTEGER NOT NULL,
            completion_percentage REAL NOT NULL,
            FOREIGN KEY(track_id) REFERENCES tracks(id) ON DELETE CASCADE
        );
        """,
        // Indices
        "CREATE INDEX IF NOT EXISTS idx_tracks_title ON tracks(title);",
        "CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks(artist_name);",
        "CREATE INDEX IF NOT EXISTS idx_tracks_spotify_id ON tracks(spotify_id);",
        "CREATE INDEX IF NOT EXISTS idx_tracks_file_hash ON tracks(file_hash);",
        "CREATE INDEX IF NOT EXISTS idx_playlist_tracks_pos ON playlist_tracks(playlist_id, position);",
        "CREATE INDEX IF NOT EXISTS idx_history_played_at ON playback_history(played_at DESC);"
    ]
}
