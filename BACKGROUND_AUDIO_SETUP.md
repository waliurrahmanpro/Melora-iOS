# Melora - iOS Background Audio & Lock Screen Setup Guide

---

## 1. Required iOS Project Capabilities (`Info.plist`)

To enable persistent background playback when the user locks their iPhone or switches apps, the app's `Info.plist` must declare the `audio` background mode:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

In Xcode, this corresponds to:
**Signing & Capabilities** -> **+ Capability** -> **Background Modes** -> Check **Audio, AirPlay, and Picture in Picture**.

---

## 2. AVAudioSession Configuration

Melora configures the audio session before playback begins:

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
try session.setActive(true)
```

- **Category `.playback`:** Allows audio to continue playing when the Silent switch is flipped on and when the app moves to the background.
- **Policy `.longFormAudio`:** Informs iOS that Melora plays continuous music tracks, optimizing system battery conservation and AirPlay routing.

---

## 3. Interruption Handling (Phone Calls, Siri, Alarms)

When an audio interruption occurs (e.g. an incoming cellular call):
1. `AVAudioSession.interruptionNotification` fires with type `.began`.
   - Melora pauses playback and records `wasPlayingBeforeInterruption = true`.
2. When the interruption ends, `interruptionNotification` fires with type `.ended`.
   - Melora inspects `interruptionOption.contains(.shouldResume)`.
   - If `shouldResume == true` and the user was playing audio before the call, Melora automatically resumes playback.

---

## 4. Audio Route Changes (Headphone Disconnect)

When a user unplugs wired headphones or disconnects a Bluetooth audio device:
1. `AVAudioSession.routeChangeNotification` fires.
2. Melora inspects the `AVAudioSessionRouteChangeReasonKey`.
3. If `reason == .oldDeviceUnavailable`, Melora **immediately pauses playback**. This prevents audio from unintentionally blasting out of the device's built-in loudspeaker in public settings.

---

## 5. Lock Screen & Control Center Controls

Driven via `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter`:

```swift
// Metadata update
var info: [String: Any] = [
    MPMediaItemPropertyTitle: track.title,
    MPMediaItemPropertyArtist: track.artistName,
    MPMediaItemPropertyPlaybackDuration: track.durationSeconds,
    MPNowPlayingInfoPropertyElapsedPlaybackTime: position.currentTimeSeconds,
    MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
]
if let image = artworkImage {
    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
}
MPNowPlayingInfoCenter.default().nowPlayingInfo = info
```

Remote command handlers registered in [`RemoteCommandHandler.swift`](file:///e:/Downloads/app/MeloraAudio/Sources/MeloraAudio/NowPlaying/RemoteCommandHandler.swift):
- Play / Pause / Toggle
- Next Track / Previous Track
- Scrubber position changes (`changePlaybackPositionCommand`)

---

## 6. Dynamic Island & iOS 18 Behavior

> [!NOTE]
> In iOS 16, 17, and 18, SpringBoard automatically displays a native **Now Playing pill** and interactive expanded view in the **Dynamic Island** whenever:
> 1. An app has an active `AVAudioSession` with category `.playback`.
> 2. `MPNowPlayingInfoCenter.default().nowPlayingInfo` is populated.
>
> Custom ActivityKit Live Activities are intended for transient real-time events (e.g. ride sharing, food delivery, sports scores). For audio playback, Apple uses the system-managed Dynamic Island Now Playing interface directly.
