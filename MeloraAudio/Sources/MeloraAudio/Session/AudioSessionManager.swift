import Foundation

#if os(iOS)
import AVFoundation
#endif

/// Delegate receiving hardware audio session events (interruptions, route changes).
public protocol AudioSessionManagerDelegate: AnyObject, Sendable {
    func audioSessionInterruptionBegan()
    func audioSessionInterruptionEnded(shouldResume: Bool)
    func audioSessionHeadphonesDisconnected()
}

/// Manages the system AVAudioSession, background audio category, interruptions, and route changes.
public final class AudioSessionManager: @unchecked Sendable {
    public weak var delegate: AudioSessionManagerDelegate?

    private var isSessionActive = false
    private let lock = NSLock()

    public init() {
        #if os(iOS)
        setupObservers()
        #endif
    }

    deinit {
        #if os(iOS)
        removeObservers()
        #endif
        deactivateSession()
    }

    /// Configures and activates the system audio session for background playback.
    public func activateSession() throws {
        lock.lock()
        defer { lock.unlock() }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
            try session.setActive(true)
            self.isSessionActive = true
        } catch {
            throw AudioEngineError.audioSessionActivationFailed(message: error.localizedDescription)
        }
        #else
        self.isSessionActive = true
        #endif
    }

    /// Deactivates the audio session with notifyOthersOnDeactivation.
    public func deactivateSession() {
        lock.lock()
        defer { lock.unlock() }

        #if os(iOS)
        guard isSessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            self.isSessionActive = false
        } catch {
            // Log or ignore non-fatal deactivation error
        }
        #else
        self.isSessionActive = false
        #endif
    }

    #if os(iOS)
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(notification:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            delegate?.audioSessionInterruptionBegan()

        case .ended:
            var shouldResume = false
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                shouldResume = options.contains(.shouldResume)
            }
            delegate?.audioSessionInterruptionEnded(shouldResume: shouldResume)

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        // Headphone or Bluetooth device unplugged/disconnected
        if reason == .oldDeviceUnavailable {
            delegate?.audioSessionHeadphonesDisconnected()
        }
    }
    #endif
}
