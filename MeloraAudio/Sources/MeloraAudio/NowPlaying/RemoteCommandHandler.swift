import Foundation
import MeloraCore

#if canImport(MediaPlayer)
import MediaPlayer
#endif

/// Delegate receiving remote command events from Control Center, Lock Screen, Dynamic Island, and AirPods.
public protocol RemoteCommandHandlerDelegate: AnyObject, Sendable {
    func remoteCommandPlay()
    func remoteCommandPause()
    func remoteCommandTogglePlayPause()
    func remoteCommandNextTrack()
    func remoteCommandPreviousTrack()
    func remoteCommandSeek(toSeconds seconds: Double)
}

/// Binds hardware and system lock screen controls via MPRemoteCommandCenter.
public final class RemoteCommandHandler: @unchecked Sendable {
    public weak var delegate: RemoteCommandHandlerDelegate?

    public init() {
        setupRemoteCommands()
    }

    deinit {
        tearDownRemoteCommands()
    }

    public func setupRemoteCommands() {
        #if canImport(MediaPlayer)
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.delegate?.remoteCommandPlay()
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.delegate?.remoteCommandPause()
            return .success
        }

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.delegate?.remoteCommandTogglePlayPause()
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.delegate?.remoteCommandNextTrack()
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.delegate?.remoteCommandPreviousTrack()
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.delegate?.remoteCommandSeek(toSeconds: positionEvent.positionTime)
            return .success
        }
        #endif
    }

    public func tearDownRemoteCommands() {
        #if canImport(MediaPlayer)
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)
        #endif
    }
}
