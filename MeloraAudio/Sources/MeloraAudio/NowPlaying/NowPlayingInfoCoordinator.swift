import Foundation
import MeloraCore

#if canImport(MediaPlayer)
import MediaPlayer
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Synchronizes playback metadata with Apple's MPNowPlayingInfoCenter (Lock Screen, Dynamic Island, Control Center).
public final class NowPlayingInfoCoordinator: @unchecked Sendable {
    private let lock = NSLock()
    private var currentTrackId: String?

    public init() {}

    /// Updates Now Playing metadata when a new track is loaded or playback begins.
    public func updateMetadata(
        for track: Track,
        position: PlaybackPosition,
        isPlaying: Bool,
        artworkImage: Any? = nil // UIImage on Apple platforms
    ) {
        lock.lock()
        defer { lock.unlock() }

        #if canImport(MediaPlayer)
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artistName,
            MPMediaItemPropertyPlaybackDuration: track.durationSeconds,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: position.currentTimeSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let album = track.albumTitle {
            info[MPMediaItemPropertyAlbumTitle] = album
        }

        #if canImport(UIKit)
        if let image = artworkImage as? UIImage {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        #endif

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        self.currentTrackId = track.id
        #endif
    }

    /// Updates elapsed time and playback rate during playback ticks without reloading full metadata.
    public func updatePlaybackState(position: PlaybackPosition, isPlaying: Bool) {
        lock.lock()
        defer { lock.unlock() }

        #if canImport(MediaPlayer)
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position.currentTimeSeconds
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        #endif
    }

    /// Clears the lock screen and Control Center Now Playing display.
    public func clearNowPlaying() {
        lock.lock()
        defer { lock.unlock() }

        #if canImport(MediaPlayer)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        self.currentTrackId = nil
        #endif
    }
}
