# MeloraData

`MeloraData` provides persistent storage, database operations, and repository implementations for Melora.

---

## Architecture & Contents

### 1. Database Engine (`Sources/MeloraData/Database/`)
- **`SQLiteSchema.swift`**: Canonical SQL DDL table creation statements, versioned migrations (`user_version`), pragmas (`PRAGMA foreign_keys = ON;`, `PRAGMA journal_mode = WAL;`), and optimized indexing strategies.
- **`SQLiteDatabase.swift`**: High-performance SQLite engine wrapping native SQLite C APIs (`sqlite3_*`) with thread-safe serialized access, prepared statements, parameter binding, row extraction, and atomic transactions.

### 2. Repositories (`Sources/MeloraData/Repositories/`)
- **`SQLiteTrackRepository.swift`**: Implements `TrackRepositoryProtocol`. Performs SQL-based track inserts, batch imports, title/artist search, pagination, updates, and deletes.
- **`SQLitePlaylistRepository.swift`**: Implements `PlaylistRepositoryProtocol`. Handles playlist CRUD, automatic aggregate computations (track count, total duration), track ordering, zero-based position shifts, and cascades.
- **`SQLitePlaybackHistoryRepository.swift`**: Implements `PlaybackHistoryRepositoryProtocol`. Logs listening sessions, queries recent tracks with joins, and computes play count aggregations.

---

## Relational Schema & Constraints

```
  +--------------+          +-------------------+          +------------------+
  |    tracks    |<--------+|  playlist_tracks  |+-------->|    playlists     |
  +--------------+ 1      * +-------------------+ *      1 +------------------+
         |                        (CASCADE)                      (CASCADE)
         |
         +-----------------+
         | 1               | 1
         v *               v *
+------------------+ +------------------+
| playback_history | |      albums      |
+------------------+ +------------------+
    (CASCADE)              (SET NULL)
```

- Foreign keys are strictly enforced.
- Deleting a `Track` cascades to remove its occurrences from `playlist_tracks` and `playback_history`.
- Deleting a `Playlist` cascades to remove all its rows in `playlist_tracks`.
- Deleting an `Artist` sets the corresponding `artist_id` in `albums` to `NULL`.
