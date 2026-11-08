# MeloraCore

`MeloraCore` contains the pure, portable domain layer of the Melora music player application. It has zero external third-party dependencies and zero coupling to iOS-specific presentation (`SwiftUI`) or platform audio runtimes (`AVFoundation`).

---

## Architecture & Contents

### 1. Domain Models (`Sources/MeloraCore/Models/`)
- **`AudioFormat.swift`**: Enum covering supported formats (`mp3`, `m4a`, `aac`, `flac`, `alac`, `wav`, `aiff`), MIME types, extensions, and lossless flags.
- **`PlaybackState.swift`**: Models `PlaybackStatus` (idle, loading, playing, paused, stopped, failed), `RepeatMode`, `ShuffleMode`, and `PlaybackPosition` (timeline progress and remaining time).
- **`Track.swift`**: The central entity representing a local audio file within the sandbox container. Immutable, `Identifiable`, `Hashable`, `Codable`, and `Sendable`.
- **`Artist.swift`**: Artist entity with optional Spotify metadata link.
- **`Album.swift`**: Album entity with release year and artwork references.
- **`Playlist.swift`**: User and imported playlist entities along with ordered `PlaylistTrack` junction structs.
- **`PlaybackHistory.swift`**: Session logging entity for listening tracking and stats.

### 2. Service Protocols (`Sources/MeloraCore/Protocols/`)
- **`AudioPlayerEngineProtocol.swift`**: Abstract contract for audio playback engines, queues, seeking, and observer delegates.
- **`DatabaseServiceProtocol.swift`**: Contract for low-level SQLite database operations, transactions, and row transformations.
- **`TrackRepositoryProtocol.swift`**: Contract for CRUD, pagination, and search queries across local audio tracks.
- **`PlaylistRepositoryProtocol.swift`**: Contract for playlist lifecycle, ordered track insertions, removals, and position compaction.
- **`PlaybackHistoryRepositoryProtocol.swift`**: Contract for logging listening sessions and querying top tracks.
- **`SpotifyServiceProtocol.swift`**: Strict contract for authorized Spotify OAuth authentication, playlist metadata, and discovery (no preview URLs, no audio ripping).
- **`FileStorageProtocol.swift`**: Sandboxed file import, absolute path resolution, and duplicate hash checking.

---

## Swift 6 & Thread Safety
All models and protocols adhere to Swift 6 strict concurrency (`Sendable`), guaranteeing thread-safe coordination across background audio queues, UI states, and database operations.
