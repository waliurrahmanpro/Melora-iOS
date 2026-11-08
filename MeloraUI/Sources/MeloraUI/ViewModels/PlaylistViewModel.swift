import Foundation
import MeloraCore
import MeloraData

#if canImport(Observation)
import Observation
#endif

@Observable
public final class PlaylistViewModel: @unchecked Sendable {
    public let playlistRepository: PlaylistRepositoryProtocol
    public let trackRepository: TrackRepositoryProtocol

    public var playlists: [Playlist] = []
    public var selectedPlaylist: Playlist?
    public var selectedPlaylistTracks: [Track] = []

    public var isCreatePresented: Bool = false
    public var newPlaylistTitle: String = ""
    public var statusMessage: String?

    public init(
        playlistRepository: PlaylistRepositoryProtocol,
        trackRepository: TrackRepositoryProtocol
    ) {
        self.playlistRepository = playlistRepository
        self.trackRepository = trackRepository
    }

    public func loadPlaylists() {
        do {
            self.playlists = try playlistRepository.getPlaylists()
        } catch {
            self.statusMessage = "Failed to load playlists: \(error.localizedDescription)"
        }
    }

    public func loadTracks(for playlist: Playlist) {
        self.selectedPlaylist = playlist
        do {
            self.selectedPlaylistTracks = try playlistRepository.getTracksForPlaylist(playlistId: playlist.id)
        } catch {
            self.statusMessage = "Failed to load playlist tracks: \(error.localizedDescription)"
        }
    }

    public func createPlaylist(title: String, description: String? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newPlaylist = Playlist(
            id: UUID().uuidString,
            title: trimmed,
            description: description,
            isImportedFromSpotify: false
        )

        do {
            try playlistRepository.createPlaylist(newPlaylist)
            self.newPlaylistTitle = ""
            self.isCreatePresented = false
            loadPlaylists()
        } catch {
            self.statusMessage = "Failed to create playlist: \(error.localizedDescription)"
        }
    }

    public func deletePlaylist(_ playlist: Playlist) {
        do {
            try playlistRepository.deletePlaylist(byId: playlist.id)
            loadPlaylists()
        } catch {
            self.statusMessage = "Failed to delete playlist: \(error.localizedDescription)"
        }
    }

    public func removeTrack(trackId: String, from playlistId: String) {
        do {
            try playlistRepository.removeTrack(trackId: trackId, fromPlaylistId: playlistId)
            if let current = selectedPlaylist {
                loadTracks(for: current)
            }
        } catch {
            self.statusMessage = "Failed to remove track: \(error.localizedDescription)"
        }
    }

    public func reorderTrack(in playlistId: String, fromIndex: Int, toIndex: Int) {
        do {
            try playlistRepository.reorderTrack(inPlaylistId: playlistId, fromPosition: fromIndex, toPosition: toIndex)
            if let current = selectedPlaylist {
                loadTracks(for: current)
            }
        } catch {
            self.statusMessage = "Failed to reorder tracks: \(error.localizedDescription)"
        }
    }
}
