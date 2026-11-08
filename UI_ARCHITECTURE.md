# Melora — SwiftUI UI Architecture

---

## 1. Architectural Pattern: Clean Architecture + MVVM

Melora’s presentation layer is structured using **Clean Architecture + MVVM**, leveraging the modern **Observation framework (`@Observable`)** introduced in iOS 17 and refined in iOS 18:

```
+-----------------------------------------------------------------------------------+
|                                PRESENTATION (SwiftUI)                             |
|  MainTabView  -  HomeView  -  SearchView  -  LibraryView  -  NowPlayingView       |
+------------------------------------------+----------------------------------------+
                                           | Observable state bindings
                                           v
+-----------------------------------------------------------------------------------+
|                                 VIEWMODELS (@Observable)                          |
|  PlayerViewModel  -  HomeViewModel  -  SearchViewModel  -  LibraryViewModel       |
+------------------------------------------+----------------------------------------+
                                           | Calls business logic & use cases
                                           v
+-----------------------------------------------------------------------------------+
|                             COORDINATORS & SERVICES                               |
|  AudioPlaybackCoordinator  -  LibraryImportService  -  SpotifyService             |
+---------------------+--------------------+--------------------+-------------------+
                      |                    |                    |
                      v                    v                    v
              [ Audio Engine ]     [ SQLite Repositories ] [ Spotify Web API Client ]
```

---

## 2. Playback State Synchronization

To prevent UI stutter and race conditions:
1. **Single Source of Truth:** `AudioPlaybackCoordinator` owns the audio engine, queue manager, and session interruptions.
2. **Observation Observer Pattern:** `PlayerViewModel` conforms to `AudioPlayerEngineObserver`. Any playback event (`audioEngineDidChangeStatus`, `audioEngineDidChangePosition`, `audioEngineDidFinishPlaying`) dispatches updates directly to `@MainActor`, updating SwiftUI view hierarchies smoothly.
3. **Decoupled Background Playback:** The audio engine (`AVPlayer`) and `AVAudioSession` run completely independently of whether SwiftUI views are mounted, dismissed, or suspended.

---

## 3. Navigation Hierarchy

```
WindowGroup
└── MainTabView (TabView)
    ├── Tab 1: HomeView (NavigationStack)
    ├── Tab 2: SearchView (NavigationStack)
    ├── Tab 3: LibraryView (NavigationStack)
    ├── Tab 4: SpotifyView (NavigationStack)
    └── Tab 5: SettingsView (NavigationStack)
    │
    └── MiniPlayerView (Floating overlay, sits above TabBar when track != nil)
        └── Tap -> Fullscreen modal sheet -> NowPlayingView
            └── Queue button -> Sheet modal -> QueueSheetView
```

---

## 4. Dynamic Island & Live Activities Clarification

> [!IMPORTANT]
> **Dynamic Island vs. ActivityKit Live Activities:**
> - In iOS 16, 17, and 18, SpringBoard **automatically** renders audio playback in the **Dynamic Island** whenever:
>   1. An app has an active `AVAudioSession` with category `.playback`.
>   2. `MPNowPlayingInfoCenter.default().nowPlayingInfo` is populated with track metadata.
> - **Live Activities (ActivityKit)** are designed for transient real-time event updates (e.g., flight tracking, food delivery, sports scores). They are not intended or required for standard audio playback.
> - Melora's audio architecture relies directly on Apple's standard Now Playing system service, ensuring zero battery drain and seamless integration across Dynamic Island, Lock Screen, and Control Center.

---

## 5. Accessibility & Dynamic Type

1. **Touch Targets:** Minimum 44×44 pt touch bounds across all interactive controls (`MeloraSpacing.minimumTouchTarget`).
2. **VoiceOver Accessibility:** Every button includes `.accessibilityLabel` and `.accessibilityHint` (e.g. "Now playing: Get Lucky by Daft Punk. Double tap to open now playing screen").
3. **Contrast:** Meets WCAG AAA standards for white text (`#FFFFFF`) against pure pitch black (`#000000`).
