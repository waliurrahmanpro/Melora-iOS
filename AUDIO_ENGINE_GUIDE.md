# Melora - AVFoundation Audio Engine Guide

---

## 1. Overview & Architecture

Melora's audio playback engine is built on Apple's native **AVFoundation** framework. It is strictly decoupled from UI presentation and persistence via clean protocol abstractions (`AudioPlayerEngineProtocol` and `AudioPlayerEngineObserver`).

```
                    +--------------------------------------------+
                    |          AudioPlaybackCoordinator          |
                    +---------------------+----------------------+
                                          |
                +-------------------------+-------------------------+
                |                         |                         |
                v                         v                         v
+-------------------------------+ +-------------------+ +-----------------------+
|    AVFoundationAudioEngine    | |   QueueManager    | |  AudioSessionManager  |
|  * AVPlayer / AVPlayerItem    | |  * Queue state    | |  * AVAudioSession     |
|  * Periodic Time Observers    | |  * Shuffle logic  | |  * Interruption Notif |
|  * Precise Seeking (CMTime)   | |  * Repeat modes   | |  * Route Change Notif |
+---------------+---------------+ +-------------------+ +-----------------------+
                |
                v
+-------------------------------+
|   NowPlayingInfoCoordinator   |
|  * MPNowPlayingInfoCenter     |
|  * MPRemoteCommandCenter      |
+-------------------------------+
```

---

## 2. Supported Formats & Codecs

AVFoundation provides low-latency, hardware-accelerated decoding on iOS for user-owned audio files:

| Format | Extensions | AVFoundation Codec / Container | Lossless? |
| :--- | :--- | :--- | :--- |
| **FLAC** | `.flac` | Free Lossless Audio Codec (iOS 11+) | Yes |
| **ALAC** | `.m4a` | Apple Lossless Audio Codec | Yes |
| **WAV** | `.wav` | LPCM (Linear Pulse Code Modulation) | Yes |
| **AIFF** | `.aiff`, `.aif` | AIFF Container / Uncompressed PCM | Yes |
| **AAC** | `.m4a`, `.aac` | Advanced Audio Coding (LC / HE) | No |
| **MP3** | `.mp3` | MPEG-1/2 Audio Layer III | No |

---

## 3. Queue Management & Shuffle Logic

The [`QueueManager`](file:///e:/Downloads/app/MeloraAudio/Sources/MeloraAudio/Engine/QueueManager.swift) maintains two separate lists:
1. `originalTracks`: The original, user-specified or album-ordered sequence.
2. `activeQueue`: The current sequence being played.

### Shuffle State Preservation:
- **Toggling Shuffle On:** The currently playing track is preserved at index 0 of `activeQueue`. The remaining tracks are randomly shuffled. This guarantees the user's active listening experience is never interrupted when turning on shuffle.
- **Toggling Shuffle Off:** The `activeQueue` is restored to `originalTracks`. The active index is updated to match the location of the currently playing track in the original order.

### Repeat Modes:
- `.off`: Playback stops automatically when the last track in the queue finishes.
- `.all`: Playback loops back to index 0 after the last track finishes.
- `.one`: The current track repeats indefinitely whenever playback reaches the end.

### Previous Track Behavior:
- If current track progress is **> 3.0 seconds**: Restarts the current track from 0.0 seconds.
- If current track progress is **<= 3.0 seconds**: Navigates to the previous track in the queue.

---

## 4. Accurate Playback History Tracking

To avoid cluttering the database with false records, [`AudioPlaybackCoordinator`](file:///e:/Downloads/app/MeloraAudio/Sources/MeloraAudio/Coordinator/AudioPlaybackCoordinator.swift) enforces strict rules:
1. **Accumulated Duration:** Active listening time is calculated across multiple pause and resume cycles.
2. **No Duplicates on Pause/Resume:** Pausing or resuming a track **never** writes a history row.
3. **Threshold Rules:** A session is only committed to `playback_history` when:
   - The track finishes naturally (`completed = true`), OR
   - The user played at least **70%** of the track duration, OR
   - The user listened for at least **30 seconds** before skipping.
