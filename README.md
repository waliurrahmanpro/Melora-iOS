# Melora — Native iOS Music Player

[![Melora iOS CI](https://github.com/waliurrahmanpro/Melora-iOS/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/waliurrahmanpro/Melora-iOS/actions/workflows/ios-ci.yml)
![Platform](https://img.shields.io/badge/Platform-iOS%2018%2B-black?style=flat&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat&logo=swift)
![UI](https://img.shields.io/badge/UI-SwiftUI-0071e3?style=flat)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20MVVM-success?style=flat)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat)

**Melora** is a high-performance native iOS music player engineered from the ground up for **iOS 18+** using **Swift 6** and **SwiftUI**. Designed with an **AMOLED Pure Pitch-Dark** aesthetic, Melora combines an audiophile-grade local audio engine for user-owned audio files with rich music discovery and playlist metadata synchronization powered by the **Spotify Web API**.

---

## 1. Key Features

- **Native AVFoundation Engine:** Full local playback pipeline supporting **FLAC, ALAC, AAC, MP3, WAV, and AIFF** with zero third-party audio bloat.
- **Background Playback & Lock Screen:** Full lock screen synchronization via `MPNowPlayingInfoCenter`, scrubber control, and remote hardware command handling via `MPRemoteCommandCenter`.
- **Intelligent Audio Session Management:** Automatic pause on headphone disconnect (`oldDeviceUnavailable`), graceful interruption handling (phone calls, alarms), and audio ducking.
- **Normalized SQLite Database:** Lightning-fast local library queries with foreign key constraints, WAL journaling, zero orphaned records, and indexed search.
- **Spotify Web API (OAuth 2.0 PKCE):** Secure authentication without client secrets, playlist metadata exploration, and artist/album browsing strictly compliant with Spotify Developer Terms.
- **Pure AMOLED Dark UI:** Pitch-black background (`#000000`) with dark charcoal cards, SF Pro rounded typography, persistent floating Mini Player, and interactive full-screen Now Playing modal.
- **Sandboxed Local File Ingestion:** Security-scoped Document Picker access, SHA-256 duplicate detection, magic byte validation, and path traversal defense.

---

## 2. Modular Architecture

Melora follows Clean Architecture principles, completely decoupling core business models and SQLite persistence from platform audio and SwiftUI view logic:

```
Melora-iOS/
├── MeloraCore/                    # Pure Swift domain models, contracts, and service protocols
│   ├── Sources/MeloraCore/        # Track, Artist, Album, Playlist, PlaybackHistory, AudioFormat
│   └── Tests/MeloraCoreTests/     # Swift Testing suite
├── MeloraData/                    # SQLite database, Spotify Web API & local storage managers
│   ├── Sources/MeloraData/
│   │   ├── Database/              # SQLiteSchema, SQLiteDatabase (C API wrapper)
│   │   ├── Repositories/          # Track, Playlist, and PlaybackHistory repositories
│   │   ├── Spotify/               # PKCE auth, API client, rate limiter, services, DTOs
│   │   └── Storage/               # LocalFileStorageManager, FileValidator, MetadataExtractor
│   └── Tests/MeloraDataTests/     # SQLite, Storage, and Spotify unit tests
├── MeloraAudio/                   # AVFoundation audio engine & system coordinators
│   ├── Sources/MeloraAudio/
│   │   ├── Engine/                # AVFoundationAudioEngine, QueueManager (Shuffle/Repeat)
│   │   ├── NowPlaying/            # NowPlayingInfoCoordinator, RemoteCommandHandler
│   │   ├── Session/               # AudioSessionManager (Interruptions, Route Changes)
│   │   └── Coordinator/           # AudioPlaybackCoordinator (Master orchestrator)
│   └── Tests/MeloraAudioTests/    # Queue and audio state machine unit tests
├── MeloraUI/                      # Native SwiftUI interface & ViewModels
│   ├── Sources/MeloraUI/
│   │   ├── DesignSystem/          # MeloraColors, MeloraTypography, MeloraSpacing, Components
│   │   ├── Navigation/            # MainTabView (5 tabs), AppNavigation
│   │   ├── ViewModels/            # 8 ViewModels using Swift's @Observable macro
│   │   └── Views/                 # Home, Search, Now Playing, Library, Playlists, Spotify, Settings
│   └── Tests/MeloraUITests/       # ViewModel state and interaction tests
├── MeloraApp/                     # iOS 18+ App Target & Application Entry
│   ├── MeloraApp.swift            # @main entry point, DI wiring, and .onOpenURL handler
│   └── Info.plist                 # UIBackgroundModes ("audio"), URL Schemes ("melora")
├── .github/workflows/             # GitHub Actions CI/CD Pipeline
│   └── ios-ci.yml                 # macOS-14, Xcode 16 matrix, SwiftLint, iOS Simulator build
├── tests/                         # Cross-platform unit verification suite (44 passing tests)
├── project.yml                    # Declarative XcodeGen configuration
├── Melora.xcodeproj/              # Committed Xcode project with shared MeloraApp scheme
└── Release/                       # ExportOptions templates for App Store & Ad-Hoc IPAs
```

---

## 3. Operations & Documentation Catalog

| Document | Description |
| :--- | :--- |
| [`PROJECT_PLAN.md`](file:///e:/Downloads/app/PROJECT_PLAN.md) | Master architectural blueprint, boundaries, and 8 completed development phases. |
| [`UI_DESIGN_SYSTEM.md`](file:///e:/Downloads/app/UI_DESIGN_SYSTEM.md) | AMOLED color tokens, typographic scales, spacing units, and reusable UI components. |
| [`UI_ARCHITECTURE.md`](file:///e:/Downloads/app/UI_ARCHITECTURE.md) | MVVM data flow, `@Observable` state bindings, and dependency injection patterns. |
| [`SCREEN_CATALOG.md`](file:///e:/Downloads/app/SCREEN_CATALOG.md) | Visual design, states, and feature breakdown for all 8 application screens. |
| [`AUDIO_ENGINE_GUIDE.md`](file:///e:/Downloads/app/AUDIO_ENGINE_GUIDE.md) | AVFoundation player implementation, queue state machine, and shuffle mechanics. |
| [`BACKGROUND_AUDIO_SETUP.md`](file:///e:/Downloads/app/BACKGROUND_AUDIO_SETUP.md) | `AVAudioSession` configuration, route changes, lock screen scrubbers, and hardware controls. |
| [`SPOTIFY_INTEGRATION.md`](file:///e:/Downloads/app/SPOTIFY_INTEGRATION.md) | Spotify OAuth 2.0 PKCE flow, rate limiting, and Developer Terms compliance rules. |
| [`AUDIO_IMPORT_GUIDE.md`](file:///e:/Downloads/app/AUDIO_IMPORT_GUIDE.md) | Document Picker importing, sandboxed storage, and AVAsset metadata extraction. |
| [`GITHUB_ACTIONS_GUIDE.md`](file:///e:/Downloads/app/GITHUB_ACTIONS_GUIDE.md) | CI/CD runner architecture, Xcode 16 matrix, artifact retention, and troubleshooting. |
| [`BUILD_AND_RELEASE_GUIDE.md`](file:///e:/Downloads/app/BUILD_AND_RELEASE_GUIDE.md) | Local Xcode build commands, Simulator debugging, physical device setup, and archiving. |
| [`CODE_SIGNING_GUIDE.md`](file:///e:/Downloads/app/CODE_SIGNING_GUIDE.md) | Apple Developer certificates, provisioning profiles, and secure GitHub Actions secrets. |
| [`IPA_BUILD_GUIDE.md`](file:///e:/Downloads/app/IPA_BUILD_GUIDE.md) | Producing `Melora.ipa` and sideloading via Sideloadly on Windows with a free Apple ID. |
| [`IPHONE_TESTING_CHECKLIST.md`](file:///e:/Downloads/app/IPHONE_TESTING_CHECKLIST.md) | Comprehensive test checklist for iOS 18 Simulator and physical iPhone devices. |
| [`RELEASE_READINESS_REPORT.md`](file:///e:/Downloads/app/RELEASE_READINESS_REPORT.md) | Production readiness evaluation, security certification, and handoff protocols. |

---

## 4. Building & Running

### Requirements
- **macOS**: Sonoma 14.5+ or Sequoia 15.0+
- **Xcode**: 16.0 or later (Swift 6.0 toolchain, iOS 18 SDK)
- **Deployment Target**: iOS 18.0+

### Opening in Xcode
```bash
# Clone the repository
git clone https://github.com/waliurrahmanpro/Melora-iOS.git
cd Melora-iOS

# Open in Xcode (zero setup required)
open Melora.xcodeproj
```

Select the **MeloraApp** scheme, choose an **iPhone 16** simulator, and press **Cmd + R**.

### Running the Verification Test Suite
Melora includes a complete cross-platform test suite runnable on Windows, macOS, and Linux:

```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

---

## 5. Policy & Legal Notice

- **Spotify Compliance:** Melora uses the Spotify Web API strictly for authorized OAuth 2.0 PKCE authentication, playlist metadata, and discovery. Melora **never** streams, downloads, caches, or rips copyrighted audio from Spotify.
- **Local Audio Ownership:** Audio playback functionality is designed exclusively for user-owned, legally acquired audio files imported into the application's isolated sandbox.
- **Intellectual Property:** Melora is an independent open-source project and is not affiliated with, endorsed by, or associated with Spotify AB.
Melora automatic build test.
