# Melora — Real Device & Simulator Testing Checklist

This document provides a comprehensive test execution checklist for verifying **Melora** on the iOS Simulator and physical iPhone devices running iOS 18+.

---

## 1. Development Host Requirements & Environment Separation

> [!NOTE]
> **Windows vs. macOS Role Distinction:**
> - **Windows Host (Current Environment)**: Source code authoring, architecture design, static file validation, schema migration testing, mock HTTP server verification, and CI/CD workflow authoring.
> - **macOS Runner / Local Mac (Required for Verification)**: Compilation via `xcodebuild`, code signing, simulator execution, and physical device USB deployment.

---

## 2. Pre-Build Environment Verification (macOS / Xcode 16+)

- [ ] macOS Sonoma 14.5+ or macOS Sequoia 15.0+ installed.
- [ ] Xcode 16.0+ installed (`xcode-select -p` points to active Xcode toolchain).
- [ ] iOS 18.0+ Simulator runtime installed via Xcode Settings > Platforms.
- [ ] Terminal verification:
  ```bash
  xcodebuild -version       # Must report Xcode 16.0+ (Build 16A242d or newer)
  swift --version            # Must report Swift 6.0+
  xcodebuild -showsdks       # Must list iphonesimulator18.x
  ```

---

## 3. iOS Simulator Verification Checklist

### A. Launch & Navigation
- [ ] Open `Melora.xcodeproj` in Xcode 16.
- [ ] Select **MeloraApp** scheme and target **iPhone 16 (iOS 18.0)**.
- [ ] Build and run (**Cmd + R**). Verify zero compiler warnings or errors.
- [ ] Verify AMOLED dark theme appearance (#000000 pitch black background).
- [ ] Verify tab navigation across all 5 tabs: **Home**, **Search**, **Library**, **Spotify**, **Settings**.

### B. Local Audio Ingestion & File Picker
- [ ] In the Simulator, open Safari and download test audio files (MP3, FLAC, M4A, WAV) to the simulator's Files app.
- [ ] In Melora, navigate to **Library** > tap **Import Audio Files**.
- [ ] Select downloaded audio files in the Document Picker sheet.
- [ ] Verify imported songs appear in the Library song list with correct title, artist, and duration.
- [ ] Verify artwork displays correctly if embedded in ID3/Vorbis tags.

### C. Playback Engine & Queue
- [ ] Tap any imported song to start playback.
- [ ] Verify audio plays through the Mac speakers.
- [ ] Verify the floating **Mini Player** appears above the tab bar.
- [ ] Tap the Mini Player to expand the full-screen **Now Playing** sheet.
- [ ] Test the scrub slider: seek to the middle of the track and verify audio skips to the new timestamp.
- [ ] Test **Pause** and **Play** buttons.
- [ ] Test **Next Track** and **Previous Track**.
- [ ] Toggle **Shuffle**: verify playback queue is randomized without changing the currently playing song.
- [ ] Toggle **Repeat**: cycle through `Off` -> `Repeat All` -> `Repeat One`.

---

## 4. Physical iPhone Testing Checklist (iOS 18+)

### A. Device Setup & Signing
- [ ] Connect iPhone running iOS 18+ via USB cable.
- [ ] In Xcode, navigate to **MeloraApp** target > **Signing & Capabilities**.
- [ ] Check **Automatically manage signing** and select your Apple Developer Team.
- [ ] Verify provisioning profile is generated with bundle ID `com.melora.music`.
- [ ] Deploy to device (**Cmd + R**).
- [ ] On iPhone: Go to **Settings > General > VPN & Device Management** and tap **Trust Developer**.
- [ ] Launch Melora from the home screen.

### B. Background Audio Playback
- [ ] Start playing a local audio track.
- [ ] Press the iPhone side button to lock the device.
- [ ] **Lock Screen**:
  - [ ] Verify track title, artist name, and album artwork appear on the Lock Screen.
  - [ ] Verify the elapsed time and remaining duration progress in real time.
  - [ ] Tap Play/Pause on the Lock Screen; verify audio pauses/resumes instantly.
  - [ ] Tap Next/Previous; verify next/previous track begins playing.
  - [ ] Drag the scrubber on the Lock Screen; verify seeking works accurately.
- [ ] **Control Center**:
  - [ ] Swipe down from the top right to open Control Center.
  - [ ] Verify the Now Playing card displays Melora metadata and controls.
- [ ] **Background Continuity**:
  - [ ] Open other applications (Safari, Messages, Maps).
  - [ ] Verify playback continues smoothly without audio stutter or app termination.

### C. Audio Route Changes & Interruptions
- [ ] **Headphone Disconnect**:
  - [ ] Connect AirPods or wired headphones. Start audio playback.
  - [ ] Remove AirPods or unplug headphones.
  - [ ] **Expected**: Playback must pause automatically (`AVAudioSession.routeChangeReason.oldDeviceUnavailable`).
- [ ] **Incoming Phone Call**:
  - [ ] Receive a phone call while playback is active.
  - [ ] **Expected**: Playback pauses cleanly (`AVAudioSession.interruptionType.began`).
  - [ ] Decline or finish the call.
  - [ ] **Expected**: Playback resumes automatically (`AVAudioSession.interruptionType.ended` with `.shouldResume`).

### D. Files App & AirDrop Sharing
- [ ] AirDrop an MP3 or FLAC file from a Mac or another phone to the iPhone.
- [ ] In Melora > Library > Import, select the AirDropped file.
- [ ] Verify file is copied into the Melora sandboxed container (`Application Support/Melora/Tracks/`).
- [ ] Connect iPhone to a PC/Mac with iTunes / Finder:
  - [ ] In Finder / iTunes File Sharing, verify the `Melora` document folder is accessible.

### E. Spotify OAuth Flow
- [ ] In Melora, navigate to the **Spotify** tab.
- [ ] Tap **Connect with Spotify**.
- [ ] Verify Safari or ASWebAuthenticationSession opens the Spotify authorization web page.
- [ ] Log in and tap **Agree**.
- [ ] Verify Safari redirects back to `melora://spotify-callback`.
- [ ] Verify Melora catches the deep link, completes the token exchange, and displays the user profile and playlists.
- [ ] Tap an imported Spotify playlist: verify metadata imports into local Melora playlists.
