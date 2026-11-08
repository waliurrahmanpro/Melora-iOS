import Foundation
import MeloraCore
import MeloraData

#if canImport(Observation)
import Observation
#endif

#if canImport(UIKit)
import UIKit
#endif

@Observable
public final class SpotifyViewModel: @unchecked Sendable {
    public let spotifyService: SpotifyServiceProtocol
    public let playlistRepository: PlaylistRepositoryProtocol

    public var isAuthenticated: Bool = false
    public var userProfile: SpotifyUserProfile?
    public var remotePlaylists: [SpotifyPlaylistMetadata] = []
    public var importedPlaylists: [Playlist] = []

    public var isConnecting: Bool = false
    public var isImporting: Bool = false
    public var statusMessage: String?

    public init(
        spotifyService: SpotifyServiceProtocol,
        playlistRepository: PlaylistRepositoryProtocol
    ) {
        self.spotifyService = spotifyService
        self.playlistRepository = playlistRepository
        self.isAuthenticated = spotifyService.isAuthenticated
    }

    public func checkAuthAndLoad() {
        self.isAuthenticated = spotifyService.isAuthenticated
        loadLocalImportedPlaylists()

        if isAuthenticated {
            loadRemotePlaylists()
        }
    }

    public func initiateLogin() {
        self.isConnecting = true
        self.statusMessage = nil

        if let authURL = spotifyService.getAuthorizationURL() {
            #if canImport(UIKit)
            DispatchQueue.main.async {
                UIApplication.shared.open(authURL)
            }
            #endif
        } else {
            Task {
                do {
                    try await spotifyService.authenticate()
                    await MainActor.run {
                        self.isConnecting = false
                        self.isAuthenticated = self.spotifyService.isAuthenticated
                        self.loadRemotePlaylists()
                    }
                } catch {
                    await MainActor.run {
                        self.isConnecting = false
                        self.statusMessage = "Authentication failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Handles incoming redirect URLs from Spotify OAuth (e.g. melora://spotify-callback?code=...&state=...)
    public func handleRedirectURL(_ url: URL) {
        guard url.scheme?.lowercased() == "melora" else { return }
        self.isConnecting = true
        Task {
            do {
                _ = try await spotifyService.handleRedirectURL(url)
                await MainActor.run {
                    self.isConnecting = false
                    self.isAuthenticated = self.spotifyService.isAuthenticated
                    self.loadRemotePlaylists()
                    self.statusMessage = "Successfully connected to Spotify!"
                }
            } catch {
                await MainActor.run {
                    self.isConnecting = false
                    self.statusMessage = "Spotify authorization failed: \(error.localizedDescription)"
                }
            }
        }
    }

    public func disconnect() {
        Task {
            try? await spotifyService.disconnect()
            await MainActor.run {
                self.isAuthenticated = false
                self.userProfile = nil
                self.remotePlaylists.removeAll()
            }
        }
    }

    public func loadRemotePlaylists() {
        Task {
            do {
                let playlists = try await spotifyService.getUserPlaylists(limit: 50, offset: 0)
                await MainActor.run {
                    self.remotePlaylists = playlists
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Failed to load Spotify playlists: \(error.localizedDescription)"
                }
            }
        }
    }

    public func loadLocalImportedPlaylists() {
        do {
            let all = try playlistRepository.getPlaylists()
            self.importedPlaylists = all.filter { $0.isImportedFromSpotify }
        } catch {
            self.statusMessage = "Failed to load local imported playlists: \(error.localizedDescription)"
        }
    }

    /// Imports metadata for a Spotify playlist into the local SQLite database.
    public func importSpotifyPlaylistMetadata(_ remote: SpotifyPlaylistMetadata) {
        self.isImporting = true
        Task {
            do {
                let newPlaylist = Playlist(
                    id: UUID().uuidString,
                    title: remote.name,
                    description: remote.description,
                    artworkPath: remote.artworkUrl,
                    isImportedFromSpotify: true,
                    spotifyPlaylistId: remote.id,
                    trackCount: remote.totalTracks
                )
                try playlistRepository.createPlaylist(newPlaylist)
                await MainActor.run {
                    self.isImporting = false
                    self.loadLocalImportedPlaylists()
                    self.statusMessage = "Imported '\(remote.name)' metadata into Melora."
                }
            } catch {
                await MainActor.run {
                    self.isImporting = false
                    self.statusMessage = "Failed to import playlist: \(error.localizedDescription)"
                }
            }
        }
    }
}
