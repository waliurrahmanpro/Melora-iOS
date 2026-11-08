import Foundation
import MeloraCore
import MeloraData
import MeloraAudio

#if canImport(Observation)
import Observation
#endif

@Observable
public final class SettingsViewModel: @unchecked Sendable {
    public let historyRepository: PlaybackHistoryRepositoryProtocol
    public let spotifyService: SpotifyServiceProtocol?

    public var pauseOnDisconnect: Bool = true
    public var autoAdvance: Bool = true
    public var isHistoryCleared: Bool = false
    public var statusMessage: String?

    public init(
        historyRepository: PlaybackHistoryRepositoryProtocol,
        spotifyService: SpotifyServiceProtocol? = nil
    ) {
        self.historyRepository = historyRepository
        self.spotifyService = spotifyService
    }

    public var isSpotifyConnected: Bool {
        return spotifyService?.isAuthenticated == true
    }

    public func clearListeningHistory() {
        do {
            try historyRepository.clearHistory()
            self.isHistoryCleared = true
            self.statusMessage = "Playback history cleared."
        } catch {
            self.statusMessage = "Failed to clear history: \(error.localizedDescription)"
        }
    }
}
