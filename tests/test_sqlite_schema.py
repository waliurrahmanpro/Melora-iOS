#!/usr/bin/env python3
"""
Melora SQLite Schema & Repository Test Suite
Validates schema definitions, constraints, indexes, cascading foreign keys,
and relational integrity using Python's standard SQLite3 engine.
"""

import sqlite3
import time
import unittest
import uuid

# Canonical DDL statements matching MeloraData/Sources/MeloraData/Database/SQLiteSchema.swift
PRAGMAS = [
    "PRAGMA foreign_keys = ON;",
    "PRAGMA journal_mode = MEMORY;",
    "PRAGMA synchronous = NORMAL;"
]

SCHEMA_STATEMENTS = [
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
    # Indices
    "CREATE INDEX IF NOT EXISTS idx_tracks_title ON tracks(title);",
    "CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks(artist_name);",
    "CREATE INDEX IF NOT EXISTS idx_tracks_spotify_id ON tracks(spotify_id);",
    "CREATE INDEX IF NOT EXISTS idx_tracks_file_hash ON tracks(file_hash);",
    "CREATE INDEX IF NOT EXISTS idx_playlist_tracks_pos ON playlist_tracks(playlist_id, position);",
    "CREATE INDEX IF NOT EXISTS idx_history_played_at ON playback_history(played_at DESC);"
]


class TestMeloraSQLiteSchema(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.row_factory = sqlite3.Row
        self.cursor = self.conn.cursor()

        # Apply pragmas
        for p in PRAGMAS:
            self.cursor.execute(p)

        # Apply schema
        for stmt in SCHEMA_STATEMENTS:
            self.cursor.execute(stmt)
        self.conn.commit()

    def tearDown(self):
        self.conn.close()

    def test_tables_and_indices_exist(self):
        self.cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = {row["name"] for row in self.cursor.fetchall()}
        expected_tables = {"tracks", "artists", "albums", "playlists", "playlist_tracks", "playback_history"}
        self.assertTrue(expected_tables.issubset(tables), f"Missing tables: {expected_tables - tables}")

        self.cursor.execute("SELECT name FROM sqlite_master WHERE type='index';")
        indices = {row["name"] for row in self.cursor.fetchall()}
        expected_indices = {
            "idx_tracks_title", "idx_tracks_artist", "idx_tracks_spotify_id",
            "idx_tracks_file_hash", "idx_playlist_tracks_pos", "idx_history_played_at"
        }
        self.assertTrue(expected_indices.issubset(indices), f"Missing indices: {expected_indices - indices}")

    def test_foreign_key_pragmas_enabled(self):
        self.cursor.execute("PRAGMA foreign_keys;")
        row = self.cursor.fetchone()
        self.assertEqual(row[0], 1, "Foreign keys must be enabled")

    def test_track_crud_and_search(self):
        track_id = str(uuid.uuid4())
        now = int(time.time())

        # 1. Insert Track
        insert_sql = """
        INSERT INTO tracks (
            id, title, artist_name, album_title, duration_ms, file_path, file_size_bytes,
            audio_format, bitrate, sample_rate, channels, spotify_id, artwork_path, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        self.cursor.execute(insert_sql, (
            track_id, "Resonance", "HOME", "Odyssey", 212000,
            "Tracks/home-resonance.flac", 25000000, "flac", 1411000, 44100, 2,
            "spotify:track:home123", "Artwork/resonance.jpg", now, now
        ))
        self.conn.commit()

        # 2. Query Track by ID
        self.cursor.execute("SELECT * FROM tracks WHERE id = ?", (track_id,))
        track = self.cursor.fetchone()
        self.assertIsNotNone(track)
        self.assertEqual(track["title"], "Resonance")
        self.assertEqual(track["artist_name"], "HOME")
        self.assertEqual(track["audio_format"], "flac")
        self.assertEqual(track["file_size_bytes"], 25000000)

        # 3. Substring Search
        search_term = "%esonanc%"
        self.cursor.execute(
            "SELECT * FROM tracks WHERE title LIKE ? OR artist_name LIKE ?;",
            (search_term, search_term)
        )
        search_results = self.cursor.fetchall()
        self.assertEqual(len(search_results), 1)
        self.assertEqual(search_results[0]["id"], track_id)

        # 4. Update Track
        self.cursor.execute(
            "UPDATE tracks SET title = ?, updated_at = ? WHERE id = ?;",
            ("Resonance (Remastered)", now + 10, track_id)
        )
        self.conn.commit()

        self.cursor.execute("SELECT title FROM tracks WHERE id = ?", (track_id,))
        updated_title = self.cursor.fetchone()["title"]
        self.assertEqual(updated_title, "Resonance (Remastered)")

        # 5. Delete Track
        self.cursor.execute("DELETE FROM tracks WHERE id = ?", (track_id,))
        self.conn.commit()
        self.cursor.execute("SELECT * FROM tracks WHERE id = ?", (track_id,))
        self.assertIsNone(self.cursor.fetchone())

    def test_track_constraints(self):
        now = int(time.time())
        # NOT NULL constraint on title
        with self.assertRaises(sqlite3.IntegrityError):
            self.cursor.execute("""
            INSERT INTO tracks (id, title, artist_name, duration_ms, file_path, file_size_bytes, audio_format, created_at, updated_at)
            VALUES (?, NULL, 'Artist', 1000, 'path', 1000, 'mp3', ?, ?);
            """, (str(uuid.uuid4()), now, now))

        # UNIQUE constraint on spotify_id
        t1_id = str(uuid.uuid4())
        t2_id = str(uuid.uuid4())
        self.cursor.execute("""
        INSERT INTO tracks (id, title, artist_name, duration_ms, file_path, file_size_bytes, audio_format, spotify_id, created_at, updated_at)
        VALUES (?, 'Track 1', 'Artist 1', 1000, 'path1', 1000, 'mp3', 'spotify_unique_1', ?, ?);
        """, (t1_id, now, now))
        self.conn.commit()

        with self.assertRaises(sqlite3.IntegrityError):
            self.cursor.execute("""
            INSERT INTO tracks (id, title, artist_name, duration_ms, file_path, file_size_bytes, audio_format, spotify_id, created_at, updated_at)
            VALUES (?, 'Track 2', 'Artist 2', 1000, 'path2', 1000, 'mp3', 'spotify_unique_1', ?, ?);
            """, (t2_id, now, now))

    def test_artist_album_foreign_key_set_null(self):
        artist_id = str(uuid.uuid4())
        album_id = str(uuid.uuid4())

        self.cursor.execute("INSERT INTO artists (id, name) VALUES (?, ?);", (artist_id, "Daft Punk"))
        self.cursor.execute(
            "INSERT INTO albums (id, title, artist_id, release_year) VALUES (?, ?, ?, ?);",
            (album_id, "Discovery", artist_id, 2001)
        )
        self.conn.commit()

        # Verify initial link
        self.cursor.execute("SELECT artist_id FROM albums WHERE id = ?;", (album_id,))
        self.assertEqual(self.cursor.fetchone()["artist_id"], artist_id)

        # Delete artist -> album's artist_id should become NULL due to ON DELETE SET NULL
        self.cursor.execute("DELETE FROM artists WHERE id = ?;", (artist_id,))
        self.conn.commit()

        self.cursor.execute("SELECT artist_id FROM albums WHERE id = ?;", (album_id,))
        self.assertIsNone(self.cursor.fetchone()["artist_id"])

    def test_playlist_tracks_ordering_and_cascade(self):
        now = int(time.time())
        playlist_id = str(uuid.uuid4())
        t1_id = str(uuid.uuid4())
        t2_id = str(uuid.uuid4())
        t3_id = str(uuid.uuid4())

        # Insert Playlist
        self.cursor.execute(
            "INSERT INTO playlists (id, title, created_at, updated_at) VALUES (?, ?, ?, ?);",
            (playlist_id, "Synthwave Mix", now, now)
        )

        # Insert 3 Tracks
        for tid, title in [(t1_id, "Track A"), (t2_id, "Track B"), (t3_id, "Track C")]:
            self.cursor.execute("""
            INSERT INTO tracks (id, title, artist_name, duration_ms, file_path, file_size_bytes, audio_format, created_at, updated_at)
            VALUES (?, ?, 'Artist', 180000, 'path', 5000000, 'flac', ?, ?);
            """, (tid, title, now, now))

        # Add tracks with explicit position indices
        self.cursor.execute("INSERT INTO playlist_tracks VALUES (?, ?, 0, ?);", (playlist_id, t1_id, now))
        self.cursor.execute("INSERT INTO playlist_tracks VALUES (?, ?, 1, ?);", (playlist_id, t2_id, now))
        self.cursor.execute("INSERT INTO playlist_tracks VALUES (?, ?, 2, ?);", (playlist_id, t3_id, now))
        self.conn.commit()

        # Query tracks preserving position order
        self.cursor.execute("""
        SELECT t.title, pt.position
        FROM playlist_tracks pt
        JOIN tracks t ON pt.track_id = t.id
        WHERE pt.playlist_id = ?
        ORDER BY pt.position ASC;
        """, (playlist_id,))
        ordered = self.cursor.fetchall()
        self.assertEqual([r["title"] for r in ordered], ["Track A", "Track B", "Track C"])
        self.assertEqual([r["position"] for r in ordered], [0, 1, 2])

        # Delete Track B -> verify cascade delete in playlist_tracks
        self.cursor.execute("DELETE FROM tracks WHERE id = ?;", (t2_id,))
        self.conn.commit()

        self.cursor.execute("SELECT track_id FROM playlist_tracks WHERE playlist_id = ?;", (playlist_id,))
        remaining_ids = [r["track_id"] for r in self.cursor.fetchall()]
        self.assertNotIn(t2_id, remaining_ids)
        self.assertEqual(len(remaining_ids), 2)

        # Delete Playlist -> verify junction table is completely cleared
        self.cursor.execute("DELETE FROM playlists WHERE id = ?;", (playlist_id,))
        self.conn.commit()

        self.cursor.execute("SELECT * FROM playlist_tracks WHERE playlist_id = ?;", (playlist_id,))
        self.assertEqual(len(self.cursor.fetchall()), 0)

    def test_playback_history_and_cascade(self):
        now = int(time.time())
        t_id = str(uuid.uuid4())

        self.cursor.execute("""
        INSERT INTO tracks (id, title, artist_name, duration_ms, file_path, file_size_bytes, audio_format, created_at, updated_at)
        VALUES (?, 'Get Lucky', 'Daft Punk', 240000, 'path', 6000000, 'mp3', ?, ?);
        """, (t_id, now, now))

        # Record 2 playback events
        self.cursor.execute("""
        INSERT INTO playback_history (track_id, played_at, duration_played_ms, completion_percentage)
        VALUES (?, ?, 240000, 1.0);
        """, (t_id, now - 100))
        self.cursor.execute("""
        INSERT INTO playback_history (track_id, played_at, duration_played_ms, completion_percentage)
        VALUES (?, ?, 120000, 0.5);
        """, (t_id, now))
        self.conn.commit()

        # Query recent history
        self.cursor.execute("""
        SELECT h.duration_played_ms, t.title
        FROM playback_history h
        JOIN tracks t ON h.track_id = t.id
        ORDER BY h.played_at DESC;
        """)
        rows = self.cursor.fetchall()
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["duration_played_ms"], 120000)
        self.assertEqual(rows[0]["title"], "Get Lucky")

        # Deleting track must cascade and clean up history
        self.cursor.execute("DELETE FROM tracks WHERE id = ?;", (t_id,))
        self.conn.commit()

        self.cursor.execute("SELECT * FROM playback_history;")
        self.assertEqual(len(self.cursor.fetchall()), 0)

    def test_transaction_rollback(self):
        now = int(time.time())
        t_id = str(uuid.uuid4())

        try:
            with self.conn:
                self.cursor.execute("""
                INSERT INTO tracks (id, title, artist_name, duration_ms, file_path, file_size_bytes, audio_format, created_at, updated_at)
                VALUES (?, 'Valid Track', 'Valid Artist', 1000, 'path', 100, 'mp3', ?, ?);
                """, (t_id, now, now))

                # Deliberate failure violating NOT NULL on title
                self.cursor.execute("""
                INSERT INTO tracks (id, title, artist_name, duration_ms, file_path, file_size_bytes, audio_format, created_at, updated_at)
                VALUES (?, NULL, 'Artist', 1000, 'path', 100, 'mp3', ?, ?);
                """, (str(uuid.uuid4()), now, now))
        except sqlite3.IntegrityError:
            pass

        # Verify the entire transaction rolled back
        self.cursor.execute("SELECT * FROM tracks WHERE id = ?;", (t_id,))
        self.assertIsNone(self.cursor.fetchone(), "Failed transaction must roll back all operations")


if __name__ == "__main__":
    unittest.main()
