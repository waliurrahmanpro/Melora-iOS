# Melora — Screen Catalog

---

## Screen 01 — Home ([`HomeView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Home/HomeView.swift))
- **Purpose:** Primary discovery dashboard welcoming the user.
- **Components:**
  - Dynamic time-of-day greeting ("Good Morning", "Good Afternoon", "Good Evening").
  - Search quick-shortcut button.
  - "Recently Played" horizontal carousel.
  - "Recently Added" local tracks list.
  - "Popular Artists" chip carousel derived from library track counts.
  - "Your Playlists" carousel.
  - Empty state prompt if the library has no songs yet.

---

## Screen 02 — Search ([`SearchView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Search/SearchView.swift))
- **Purpose:** Instant local search with optional Spotify catalog metadata discovery.
- **Components:**
  - Search bar with clear button and real-time debounce.
  - Category selector pills: `All`, `Tracks`, `Artists`, `Albums`, `Spotify`.
  - Local matching songs with format badges and duration.
  - Local matching artists and albums.
  - Remote Spotify catalog discovery results (when authenticated).
  - Empty state and loading indicator.

---

## Screen 03 — Now Playing ([`NowPlayingView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Player/NowPlayingView.swift))
- **Purpose:** Fullscreen immersive playback experience.
- **Components:**
  - Hero album cover artwork (up to 340×340 pt) with soft violet elevation shadow.
  - Track title, artist name, and lossless format badge.
  - Interactive scrub slider with drag gestures and monospaced timestamp indicators.
  - Main controls: Shuffle toggle, Previous track, 68 pt Play/Pause button, Next track, Repeat cycle.
  - Secondary controls: Favorite heart button, Queue sheet trigger (`QueueSheetView`), dismiss chevron.

---

## Screen 04 — Library ([`LibraryView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Library/LibraryView.swift))
- **Purpose:** Central management of the user's local music collection.
- **Components:**
  - Segmented control: `Songs`, `Artists`, `Albums`, `Recent`.
  - Library stats header ("48 songs • 3 hr 12 min").
  - Sort menu: Title (A-Z, Z-A), Artist (A-Z), Duration, Date Added.
  - Codec filter pills: `All Formats`, `FLAC`, `ALAC`, `MP3`, `WAV`, `AAC`, `AIFF`.
  - Swipe to delete track with confirmation.
  - Document Picker (`.fileImporter`) trigger button in toolbar with import progress HUD.

---

## Screen 05 — Playlists ([`PlaylistView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Playlists/PlaylistView.swift))
- **Purpose:** User custom playlists and imported Spotify playlists.
- **Components:**
  - Playlist list with artwork, track count, duration, and Spotify import badge.
  - "+ New Playlist" creation dialog.
  - Navigation to `PlaylistDetailView`:
    - Large playlist artwork header.
    - Play All and Shuffle buttons.
    - Ordered track list with track numbers and removal options.

---

## Screen 06 — Spotify ([`SpotifyView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Spotify/SpotifyView.swift))
- **Purpose:** Spotify Web API integration and playlist metadata importing.
- **Components:**
  - Connect with Spotify button (OAuth 2.0 PKCE).
  - Connected account status card with Disconnect option.
  - User Spotify playlists list with "Import" buttons.
  - Imported into Melora section.
  - Spotify Developer Terms compliance statement.

---

## Screen 07 — Downloads / Local Storage ([`DownloadsView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Downloads/DownloadsView.swift))
- **Purpose:** Sandboxed file storage inspection and cleanup.
- **Components:**
  - Total storage used card (e.g. "1.8 GB used by 48 tracks").
  - Storage breakdown by codec (FLAC, MP3, WAV, M4A).
  - Track list displaying exact on-disk file sizes and sample rates.
  - Direct file deletion action.

---

## Screen 08 — Settings ([`SettingsView.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/Views/Settings/SettingsView.swift))
- **Purpose:** Audio behaviors, privacy, and app information.
- **Components:**
  - Audio toggles: "Pause on Headphone Disconnect", "Auto-Advance to Next Track".
  - History & Privacy: "Clear Playback History" button.
  - Spotify account connection indicator.
  - About Melora: Version, Target (iOS 18+), Swift 6, AVFoundation engine, ArchiveTune functional reference acknowledgement.
