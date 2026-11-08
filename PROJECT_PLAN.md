# Melora - Native iOS Music Player: Project Architecture & Execution Plan

---

## 1. Executive Summary & Objective

**Melora** is a high-performance, native iOS music player engineered for **iOS 18+**, built exclusively with **Swift** and **SwiftUI**. Melora provides an audiophile-grade local playback experience for user-owned audio files, enriched with metadata, library discovery, and playlist synchronization powered by the **Spotify Web API (OAuth 2.0 PKCE)**.

### Core Principles & Compliance
- **User-Owned Audio Core:** The primary audio engine is dedicated solely to user-owned, legally acquired local audio files (MP3, AAC, FLAC, ALAC, WAV) imported into the iOS app sandbox.
- **Spotify Compliance & Terms of Service:** Melora strictly adheres to the **Spotify Developer Terms of Service** and Developer Policy:
  - Spotify integration provides authorized OAuth 2.0 PKCE authentication, user playlist metadata, saved tracks where permitted, artist profiles, album information, and music discovery.
  - **No Playback Dependency on `preview_url`:** The Spotify `preview_url` attribute is deprecated, nullable, and not guaranteed by Spotify. Melora does not depend on `preview_url` for audio playback.
  - **Zero Piracy / No Ripping:** Melora will **never** attempt to stream, download, cache, or extract copyrighted Spotify audio.
- **Native Experience:** Designed with iOS 18 human interface patterns, Swift 6 concurrency, the `@Observable` macro, and SwiftUI.
- **Robust Audio Core:** Utilizing Apple's `AVFoundation` framework (`AVQueuePlayer` / `AVAudioEngine`) with comprehensive background audio playback, lock screen controls (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`), and audio session interruption handling.
- **Persistent Local Database:** High-performance, zero-overhead SQLite database managing tracks, artists, albums, playlists, playback history, and metadata mappings.
- **Realistic Cross-Platform Development on Windows:** Engineered and structured on **Windows** using a strictly decoupled, modular architecture without relying on fake macOS toolchains or untestable build scripts, paired with a cloud-native CI/CD workflow (GitHub Actions) for Xcode verification.

---

## 2. Functional Reference Analysis: ArchiveTune vs. Melora

Melora uses **ArchiveTune** (`rukamori/ArchiveTune`) as its functional reference. ArchiveTune is an open-source Android music client written in Kotlin with Jetpack Compose. Below is the functional and architectural mapping from Android/ArchiveTune concepts to native iOS/Melora standards:

| Architectural Component | ArchiveTune (Android Reference) | Melora (Native iOS 18 Architecture) | Melora Rationale & Implementation Strategy |
| :--- | :--- | :--- | :--- |
| **Language & Concurrency** | Kotlin, Coroutines, StateFlow, CoroutineScope | Swift 6, Structured Concurrency (`async`/`await`, `TaskGroup`, `@MainActor`, Actors) | Swift 6 data-race safety guarantees thread-safe audio state updates and background database operations. |
| **UI Framework** | Jetpack Compose, Material 3, ViewModel | SwiftUI, Observation Framework (`@Observable`), NavigationStack | Idiomatic iOS 18 human interface guidelines, smooth sheet presentations, and zero UIKit legacy bloat. |
| **Audio Playback Engine** | Media3 / ExoPlayer, MediaSessionService | `AVFoundation` (`AVQueuePlayer`, `AVPlayerItem`), `AVAudioSession` | Low-latency hardware-accelerated playback for local files on iOS with direct OS-level battery optimization. |
| **Background Playback & Lock Screen** | Foreground Service, MediaSessionCompat, Notification with media style | `UIBackgroundModes = ["audio"]`, `MPNowPlayingInfoCenter`, `MPRemoteCommandCenter` | Required by iOS for background continuous playback and Control Center / Lock Screen / Dynamic Island integration. |
| **Local Persistence** | Android Room ORM (SQLite abstraction), KSP | Direct SQLite / GRDB / SQLite.swift (Pure SQL migrations & queries) | Deterministic cross-platform testable schema, zero reliance on proprietary Android runtime or heavy dependencies. |
| **Metadata & Discovery Provider** | YouTube Music (NewPipe / Innertube scraping & Ktor clients) | Spotify Web API (Official REST API with OAuth 2.0 PKCE) | Compliant, official REST API contract for metadata, search, playlists, and album art without fragile scraping. |
| **Local File Discovery** | Android MediaStore & Storage Access Framework (SAF) | iOS `UIDocumentPickerViewController`, Security-Scoped Bookmarks, App Sandbox Documents | Strict iOS sandbox compliance; persistent file access using `URL.startAccessingSecurityScopedResource()`. |
| **Audio Effects / EQ** | Android DynamicsProcessing / Equalizer API | `AVAudioEngine` + `AVAudioUnitEQ` (multi-band parametric/graphic EQ) | Native digital signal processing (DSP) built into AVFoundation. |

---

## 3. Windows Development Reality & Cross-Platform Plan

### 3.1 Hard Technical Boundaries
Developing a native iOS application on a Windows host requires acknowledging platform constraints:
1. **No Local Xcode / Simulator:** The Apple iOS SDK, `SwiftUI` compiler support for iOS targets, `AVFoundation` iOS runtime, and the iOS Simulator cannot execute natively on Windows.
2. **No Fake Build Configurations:** We will **not** attempt to simulate or mock iOS builds via unofficial Windows toolchains, which produce untestable and brittle artifacts.
3. **Valid Local Verification:** We **can** validate pure Swift code, data models, business logic, SQL schemas, network parsers, and mock state managers on Windows using unit tests and script runners (Node.js/Python validation scripts for schemas and API mocks).
4. **Cloud / CI Compilation:** Real compilation against the iOS 18 SDK, SwiftUI view verification, and `.ipa` generation will be delegated to **GitHub Actions** running on official `macos-14` / `macos-15` runners with Xcode 16+.

### 3.2 Strategy for Developing on Windows

```
+----------------------------------------------------------------------------------+
|                              LOCAL WINDOWS WORKSPACE                             |
|                                                                                  |
|  [ Pure Swift Domain Logic ]    [ SQLite Schema & Queries ]  [ Spotify API Specs ]|
|  - Models (Track, Playlist)     - Table Definitions         - OAuth PKCE logic   |
|  - State Machines & Reducers   - Migration Scripts         - DTOs & JSON Decoders|
|  - Player Protocols             - Indexing Strategies       - Request Builders   |
|                                                                                  |
|  [ Local Verification Harness ]                                                 |
|  - Python / Node Schema Validator & Test Runner                                  |
|  - Static Code Analysis & Documentation Checks                                   |
+----------------------------------------+-----------------------------------------+
                                         | Git Push / PR
                                         v
+----------------------------------------------------------------------------------+
|                     REMOTE CI / CD (GitHub Actions - macOS Runner)               |
|                                                                                  |
|  - Xcode 16+ Build Matrix (iOS 18.0 SDK)                                         |
|  - `xcodebuild -scheme Melora -destination 'platform=iOS Simulator,name=iPhone 16'` |
|  - Unit & Integration Test Suite Execution                                       |
|  - SwiftLint / SwiftFormat Static Analysis                                       |
|  - TestFlight / IPA Artifact Distribution (Automated Releases)                   |
+----------------------------------------------------------------------------------+
```

---

## 4. Architectural Boundaries: Portable vs. Platform-Specific

Melora strictly decouples pure business logic and contracts from iOS-specific platform implementations.

```
                    +--------------------------------------------+
                    |             PRESENTATION LAYER             |
                    |  SwiftUI Views, ViewModels, NavigationStack |
                    +---------------------+----------------------+
                                          |
                                          v
                    +--------------------------------------------+
                    |                DOMAIN LAYER                |
                    |  * Portable Models (Track, Album, Playlist)|
                    |  * Player Interfaces (AudioEngineProtocol) |
                    |  * Auth & Sync Protocols                   |
                    |  * Database Protocols & Use Cases          |
                    +----------+---------------------+-----------+
                               |                     |
             +-----------------+                     +-----------------+
             v                                                         v
+-----------------------------+                           +-----------------------------+
|      DATA & STORAGE         |                           |      AUDIO & SYSTEM         |
|  * SQLite Engine & Schemas  |                           |  * AVFoundation (AVPlayer)  |
|  * Local File Storage Mgr   |                           |  * AVAudioSession Manager   |
|  * Spotify OAuth 2.0 PKCE   |                           |  * NowPlayingInfo Center    |
|  * Spotify REST Client      |                           |  * Remote Command Center    |
+-----------------------------+                           +-----------------------------+
```

---

## 5. Technical Specifications & Limitations

### 5.1 Spotify Web API Integration & Legal Boundaries
> [!IMPORTANT]
> **Spotify Developer Terms Compliance:**
> 1. **Discovery & Metadata:** Spotify Web API is used exclusively for user authentication (OAuth 2.0 PKCE), playlist metadata ingestion, user library exploration, artist/album information, and music discovery.
> 2. **Deprecated & Nullable Preview URLs:** Melora does **not** rely on `preview_url` for music playback.
> 3. **Audio Playback Exclusivity:** The primary playback engine plays user-owned local audio files imported into the app container. Melora never downloads, rips, or extracts copyrighted audio from Spotify.
> 4. **Playlist Reconciliation:** Melora allows users to view their Spotify playlists and match track titles and artists with their local audio library files.

### 5.2 Spotify OAuth 2.0 PKCE Flow
1. **Code Verifier:** Generate a cryptographically random string (43–128 characters, high-entropy).
2. **Code Challenge:** Calculate SHA-256 hash of the verifier, Base64URL-encoded without padding.
3. **Authorization Request:** Launch `ASWebAuthenticationSession` with:
   - `client_id`: Configured application ID.
   - `response_type`: `code`.
   - `redirect_uri`: `melora://spotify-callback`.
   - `code_challenge_method`: `S256`.
   - `scope`: `user-read-private user-read-email playlist-read-private playlist-read-collaborative user-library-read`.
4. **Token Exchange:** Post `code` and `code_verifier` to `https://accounts.spotify.com/api/token` to receive `access_token` and `refresh_token`.
5. **Secure Token Storage:** Store credentials in iOS Keychain (`kSecClassGenericPassword`).

### 5.3 Local Audio Files & Ingestion Engine
- **Sandboxed File Ingestion:**
  - Files imported via `UIDocumentPickerViewController` or iOS Files app.
  - Copied into the app's `Library/Application Support/Melora/Tracks/` directory to prevent system cleanup.
  - Metadata extraction using `AVURLAsset` (ID3 tags, vorbis comments, embedded album artwork, duration, sample rate, bit rate).
- **Supported Audio Formats:**
  - Native AVFoundation codecs: AAC (`.m4a`, `.aac`), ALAC (`.m4a`), MP3 (`.mp3`), FLAC (`.flac`), LPCM/WAV (`.wav`), AIFF (`.aiff`).
- **Offline Playback:**
  - Local tracks are played directly from local disk URLs (`file://...`) through `AVPlayerItem`.
  - Zero network requirement for local library playback.

### 5.4 SQLite Database Schema Design
Melora uses a normalized relational schema designed for instant search, queue operations, and metadata synchronization:

```sql
-- Tracks Table (Local user-owned audio files with optional Spotify metadata mapping)
CREATE TABLE IF NOT EXISTS tracks (
    id TEXT PRIMARY KEY,               -- UUID or Hash
    title TEXT NOT NULL,
    artist_name TEXT NOT NULL,
    album_title TEXT,
    duration_ms INTEGER NOT NULL,
    file_path TEXT NOT NULL,           -- Local sandboxed file path
    file_size_bytes INTEGER NOT NULL,
    audio_format TEXT NOT NULL,        -- mp3, m4a, flac, wav, aac, alac
    bitrate INTEGER,
    sample_rate INTEGER,
    channels INTEGER DEFAULT 2,
    spotify_id TEXT UNIQUE,            -- Optional Spotify Track ID for metadata linkage
    artwork_path TEXT,                 -- Local cached thumbnail path
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Artists Table
CREATE TABLE IF NOT EXISTS artists (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    spotify_id TEXT UNIQUE,
    artwork_url TEXT
);

-- Albums Table
CREATE TABLE IF NOT EXISTS albums (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist_id TEXT,
    release_year INTEGER,
    artwork_path TEXT,
    spotify_id TEXT UNIQUE,
    FOREIGN KEY(artist_id) REFERENCES artists(id) ON DELETE SET NULL
);

-- Playlists Table
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

-- Playlist Tracks Junction (Maintains exact playlist track order)
CREATE TABLE IF NOT EXISTS playlist_tracks (
    playlist_id TEXT NOT NULL,
    track_id TEXT NOT NULL,
    position INTEGER NOT NULL,
    added_at INTEGER NOT NULL,
    PRIMARY KEY(playlist_id, track_id),
    FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
    FOREIGN KEY(track_id) REFERENCES tracks(id) ON DELETE CASCADE
);

-- Playback History Table
CREATE TABLE IF NOT EXISTS playback_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    track_id TEXT NOT NULL,
    played_at INTEGER NOT NULL,
    duration_played_ms INTEGER NOT NULL,
    completion_percentage REAL NOT NULL,
    FOREIGN KEY(track_id) REFERENCES tracks(id) ON DELETE CASCADE
);

-- Optimized Indices
CREATE INDEX IF NOT EXISTS idx_tracks_title ON tracks(title);
CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks(artist_name);
CREATE INDEX IF NOT EXISTS idx_tracks_spotify_id ON tracks(spotify_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_pos ON playlist_tracks(playlist_id, position);
CREATE INDEX IF NOT EXISTS idx_history_played_at ON playback_history(played_at DESC);
```

### 5.5 Background Playback Lifecycle
1. **Capabilities:** `UIBackgroundModes` configured with `audio` in `Info.plist`.
2. **Audio Session Activation:**
   ```swift
   try AVAudioSession.sharedInstance().setCategory(
       .playback,
       mode: .default,
       policy: .longFormAudio
   )
   try AVAudioSession.sharedInstance().setActive(true)
   ```
3. **Continuous Queue Management:** Maintain a background playback queue that auto-advances using `AVPlayerItemDidPlayToEndTimeNotification`.
4. **Lock Screen Synchronization:** Push state updates to `MPNowPlayingInfoCenter` on playback status changes, seek events, and track transitions.
5. **System Command Handling:** Intercept hardware buttons, AirPods double-taps, Apple Watch commands, and CarPlay events via `MPRemoteCommandCenter`.

---

## 6. Project Directory Structure

```
Melora/
├── .github/
│   └── workflows/
│       ├── ios-ci.yml             # GitHub Actions Xcode 16 / iOS 18 build & test
│       └── lint.yml               # SwiftLint validation
├── MeloraCore/                    # Pure Swift / Portable Domain Logic
│   ├── Package.swift              # Swift Package definition
│   ├── Sources/
│   │   ├── Models/                # Track, Album, Artist, Playlist, PlaybackHistory, PlaybackState
│   │   ├── Protocols/             # AudioPlayerEngineProtocol, DatabaseServiceProtocol, Repositories
│   │   ├── State/                 # State reducers, QueueManager
│   │   └── Utilities/             # TimeFormatters, HashUtils, SearchMatchEngine
│   └── Tests/                     # Unit tests executable on any platform
├── MeloraData/                    # Storage, Database & Networking
│   ├── Sources/
│   │   ├── Database/              # SQLite database manager, SQL schemas, migrations
│   │   ├── Repositories/          # TrackRepository, PlaylistRepository, HistoryRepository
│   │   ├── Spotify/               # SpotifyOAuthService, SpotifyAPIClient, DTOs
│   │   └── Storage/               # LocalAudioScanner, AudioMetadataExtractor, FileSandboxManager
│   └── Tests/                     # Schema tests, parser tests, mock network tests
├── MeloraAudio/                   # Native Audio & System Integration (iOS-specific)
│   └── Sources/
│       ├── Engine/                # MeloraAVAudioEngine, AVQueuePlayer wrapper
│       ├── Session/               # AudioSessionManager, InterruptionHandler
│       └── NowPlaying/            # NowPlayingInfoCoordinator, RemoteCommandHandler
├── MeloraApp/                     # iOS 18 Application & SwiftUI UI Layer (iOS-specific)
│   ├── MeloraApp.swift            # SwiftUI App Entrypoint (@main)
│   ├── Info.plist                 # Permissions, Background Modes, URL Schemes
│   ├── Resources/                 # Assets.xcassets, Color palettes, LaunchScreen
│   ├── ViewModels/                # PlayerViewModel, LibraryViewModel, SearchViewModel
│   ├── Views/
│   │   ├── NowPlaying/            # Fullscreen player, mini player, scrubber, volume
│   │   ├── Library/               # Songs, Artists, Albums, Local folder browser
│   │   ├── Playlists/             # Playlist list, playlist detail, track reordering
│   │   ├── Spotify/               # OAuth login view, playlist import view, sync status
│   │   ├── Common/                # Glassmorphic cards, artwork loaders, list rows
│   │   └── Settings/              # Audio quality, cache management, equalizer
├── tests/                         # Local Windows test harness
│   ├── test_sqlite_schema.py      # SQLite schema, indices, foreign keys, cascades test suite
│   ├── test_models_json.py        # Model serialization & round-trip verification
│   └── test_spotify_contracts.py  # Spotify REST DTO schema verification
├── PROJECT_PLAN.md                # Master Architecture & Execution Plan (This Document)
└── README.md                      # Project introduction and build instructions
```

---

## 7. Phased Implementation Roadmap

### Phase 1: Planning, Architectural Specifications & Schema Design (COMPLETED)
- [x] Analyze ArchiveTune architecture and functional paradigms.
- [x] Define realistic cross-platform constraints for Windows development.
- [x] Specify layer separation between portable Swift logic and iOS-specific frameworks.
- [x] Document SQLite relational schema, index strategy, and migration plan.
- [x] Integrate Spotify Developer Terms compliance (no preview_url dependency, no ripping, discovery/metadata only).
- [x] Create comprehensive `PROJECT_PLAN.md`.

### Phase 2: Core Domain Models, Protocols & Local SQLite Engine (COMPLETED)
- [x] Define pure Swift domain models (`Track`, `Album`, `Artist`, `Playlist`, `PlaybackHistory`, `AudioFormat`, `PlaybackState`).
- [x] Define service protocols (`AudioPlayerEngineProtocol`, `DatabaseServiceProtocol`, `TrackRepositoryProtocol`, `PlaylistRepositoryProtocol`, `PlaybackHistoryRepositoryProtocol`, `SpotifyServiceProtocol`, `FileStorageProtocol`).
- [x] Implement portable SQLite database manager with schema creation, CRUD operations, transactions, and cascade deletions.
- [x] Implement repository implementations (`SQLiteTrackRepository`, `SQLitePlaylistRepository`, `SQLitePlaybackHistoryRepository`).
- [x] Add unit test harness for domain models, SQLite operations, and relational integrity.
- [x] Document all files and architecture decisions.

### Phase 3: Spotify Web API Integration & Network Layer (COMPLETED)
- [x] Implement PKCE cryptography helper (RFC 7636 S256 challenge, verifier generation, CSRF state protection).
- [x] Create Spotify OAuth authorization URL builder, callback handler, and token exchange manager.
- [x] Define strongly-typed Swift Decodable DTOs for Spotify REST API responses (User Playlists, Tracks, Artists, Albums, Search).
- [x] Implement token lifecycle management with proactive refresh and Apple Keychain secure storage abstraction.
- [x] Implement Spotify Web API client with automatic rate limit handling (HTTP 429 Retry-After) and 401 retry cycle.
- [x] Implement domain mapper translating Spotify DTOs to MeloraCore entities without audio streaming dependencies.
- [x] Create unit tests and mock server test suite validating network contracts, token flows, and PKCE math.
- [x] Create SPOTIFY_INTEGRATION.md documenting developer setup, scopes, and Development Mode limits.

### Phase 4: Local Audio Ingestion & File Storage Manager (COMPLETED)
- [x] Implement sandboxed file storage manager (`LocalFileStorageManager`) with structured `Tracks/` and `Artwork/` folders.
- [x] Implement streamed chunk-by-chunk SHA-256 calculation (64 KB buffers) to prevent full-memory file buffering.
- [x] Implement content validation with magic byte signature checks (FLAC, MP3, WAV, AIFF, M4A) and path traversal prevention.
- [x] Implement audio metadata extraction (`AudioMetadataExtractor`) using AVFoundation with cross-platform tag fallback.
- [x] Implement security-scoped URL access handler (`AudioFileImporter`) for document picker and SwiftUI `.fileImporter`.
- [x] Implement atomic batch ingestion pipeline (`LibraryImportService`) with orphan file cleanup on failure.
- [x] Implement library management (`LibraryFilterService`): Recently Added, search, artist/album/format filtering, sorting, and safe deletion.
- [x] Create comprehensive AUDIO_IMPORT_GUIDE.md and Windows-compatible unit test suite (27 passing tests).

### Phase 5: AVFoundation Audio Engine & Background Playback (COMPLETED)
- [x] Implement native AVFoundation engine (`AVFoundationAudioEngine`) with periodic time observers and seeking.
- [x] Implement queue manager (`QueueManager`) with repeat modes (`off`, `all`, `one`) and shuffle preserving active track identity.
- [x] Implement system audio session coordinator (`AudioSessionManager`) with `.playback` category, interruption recovery, and headphone disconnect auto-pause.
- [x] Implement lock screen and Control Center synchronization (`NowPlayingInfoCoordinator`) with artwork and scrubber support.
- [x] Implement hardware remote command routing (`RemoteCommandHandler`) for Play, Pause, Next, Previous, and Scrubbing.
- [x] Implement master coordinator (`AudioPlaybackCoordinator`) integrating audio engine, lock screen, and duplicate-free history logging.
- [x] Create comprehensive AUDIO_ENGINE_GUIDE.md and BACKGROUND_AUDIO_SETUP.md.
- [x] Create unit tests and portable test suite (34 passing tests across Phase 02, 03, 04, and 05).

### Phase 6: SwiftUI User Interface (iOS 18 Native) (COMPLETED)
- [x] Create AMOLED dark design system: `MeloraColors`, `MeloraTypography`, `MeloraSpacing`, `MeloraTheme`, and `MeloraComponents`.
- [x] Implement `NavigationStack` root architecture (`AppNavigation`, `MainTabView`) and persistent bottom `MiniPlayerView`.
- [x] Build full-screen `NowPlayingView` with sheet presentation, scrubber, playback controls, repeat/shuffle toggles, and volume control.
- [x] Build Screen 01 (`HomeView`): personalized greeting, quick play cards, recently played carousel, recently added tracks, and library stats.
- [x] Build Screen 02 (`SearchView`): dual-mode local and Spotify catalog search with debounce and category filtering.
- [x] Build Screen 04 (`LibraryView`): tabbed browsing (Tracks, Artists, Albums, Formats), sorting, and batch deletion.
- [x] Build Screen 05 (`PlaylistView`): playlist creation, editing, track reordering, and playback triggering.
- [x] Build Screen 06 (`SpotifyView`): OAuth authorization status, profile banner, playlist explorer, and local library import flow.
- [x] Build Screen 07 (`DownloadsView`): security-scoped system file importer, batch progress tracking, and format validation.
- [x] Build Screen 08 (`SettingsView`): audio quality settings, cache management, storage breakdown, and system info.
- [x] Create 8 dedicated ViewModels with `@MainActor` state binding to core coordinators and SQLite repositories.
- [x] Create documentation (`UI_DESIGN_SYSTEM.md`, `UI_ARCHITECTURE.md`, `SCREEN_CATALOG.md`) and unit test suite (`ViewModelTests.swift` / `test_view_models.py`).

### Phase 7: GitHub Actions CI/CD Pipeline & Automated Verification (COMPLETED)
- [x] Create `.github/workflows/ios-ci.yml` targeting Xcode 16 / macOS Sonoma runner (`macos-14`).
- [x] Configure automated matrix testing of Swift 6 packages (`MeloraCore`, `MeloraData`, `MeloraAudio`, `MeloraUI`).
- [x] Configure SwiftLint static code analysis (`.swiftlint.yml`) with GitHub Actions inline error reporting.
- [x] Configure headless iOS 18 Simulator compilation (`xcodebuild` targeting `generic/platform=iOS Simulator`).
- [x] Configure artifact collection and retention for SPM build logs and Xcode simulator logs.
- [x] Generate declarative `project.yml` for XcodeGen and committed `Melora.xcodeproj` with shared `MeloraApp.xcscheme`.
- [x] Create release configuration, archive scheme, and `ExportOptions.plist.template` for App Store Connect distribution.
- [x] Create automated iOS build validation suite (`test_ios_build_validation.py`) verifying `Info.plist`, deployment targets, background audio, URL schemes, and entry points.
- [x] Create comprehensive operations documentation: `GITHUB_ACTIONS_GUIDE.md`, `BUILD_AND_RELEASE_GUIDE.md`, and `CODE_SIGNING_GUIDE.md`.

### Phase 8: Final Integration & Real Device Readiness (COMPLETED)
- [x] Perform full project audit across all 56 Swift source files, packages, and access control boundaries.
- [x] Wire up OAuth 2.0 PKCE callback handling via `.onOpenURL` and `handleRedirectURL` in `MeloraApp` and `SpotifyViewModel`.
- [x] Make dynamic Xcode 16 runner detection fully generic in `.github/workflows/ios-ci.yml`.
- [x] Document physical iPhone testing checklist across background audio, interruptions, route changes, AirDrop, and Lock Screen controls.
- [x] Document Windows-friendly `.ipa` sideloading workflow via Sideloadly with personal 7-day Apple ID certificates.
- [x] Create comprehensive operational deliverables: `PHASE_08_AUDIT_REPORT.md`, `IPHONE_TESTING_CHECKLIST.md`, `IPA_BUILD_GUIDE.md`, and `RELEASE_READINESS_REPORT.md`.

---

## 8. Risk Assessment & Mitigation Strategies

| Risk / Limitation | Impact | Mitigation Strategy |
| :--- | :--- | :--- |
| **No Local macOS / Xcode on Windows** | Inability to compile SwiftUI views or launch simulator locally. | Maintain 100% decoupling of portable Swift logic. Validate data models, SQLite schemas, and network contracts locally. Leverage GitHub Actions macOS runners for full Xcode verification. |
| **Spotify Terms of Service Compliance** | App rejection or API revocation if audio is scraped/ripped. | Zero streaming/ripping from Spotify. Spotify API is used strictly for authorized OAuth metadata, playlists, and discovery. Full audio is provided exclusively by user-owned local files. |
| **Spotify `preview_url` Deprecation** | Audio failures if relying on preview URLs. | Completely removed `preview_url` as a playback dependency. Playback is driven exclusively by local audio file paths. |
| **iOS Background Audio Suspension** | App suspended in background if audio engine is improperly configured. | Correctly configure `UIBackgroundModes = ["audio"]`, maintain active `AVAudioSession`, and ensure `AVPlayer` remains active during track transitions. |
| **File Sandbox & Security Scope Expiry** | Imported files outside container become inaccessible on app restart. | Copy user-selected audio files directly into the app's sandboxed `Application Support` storage upon import, ensuring perpetual offline availability. |
| **Large Local Audio Libraries Performance** | UI stuttering when scanning/displaying 10,000+ local tracks. | Paginated SQLite queries with indexed lookups, asynchronous background file scanning, and lightweight SwiftUI `LazyVStack` list rendering. |
