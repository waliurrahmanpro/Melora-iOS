import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Screen 05 — Playlists: Collection of user and imported Spotify playlists with CRUD actions.
public struct PlaylistView: View {
    @Bindable public var viewModel: PlaylistViewModel
    @Bindable public var playerViewModel: PlayerViewModel

    public init(viewModel: PlaylistViewModel, playerViewModel: PlayerViewModel) {
        self.viewModel = viewModel
        self.playerViewModel = playerViewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MeloraColors.amoledBlack.ignoresSafeArea()

                if viewModel.playlists.isEmpty {
                    MeloraEmptyState(
                        systemImage: "music.note.list",
                        title: "No Playlists Yet",
                        message: "Create your first custom playlist to group your favorite songs.",
                        buttonTitle: "Create Playlist"
                    ) {
                        viewModel.isCreatePresented = true
                    }
                } else {
                    List {
                        ForEach(viewModel.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(
                                playlist: playlist,
                                viewModel: viewModel,
                                playerViewModel: playerViewModel
                            )) {
                                playlistRow(playlist: playlist)
                            }
                            .listRowBackground(MeloraColors.amoledBlack)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deletePlaylist(playlist)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.isCreatePresented = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MeloraColors.accent)
                    }
                }
            }
            .onAppear {
                viewModel.loadPlaylists()
            }
            .alert("Create New Playlist", isPresented: $viewModel.isCreatePresented) {
                TextField("Playlist Name", text: $viewModel.newPlaylistTitle)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    viewModel.createPlaylist(title: viewModel.newPlaylistTitle)
                }
            }
        }
    }

    private func playlistRow(playlist: Playlist) -> some View {
        HStack(spacing: MeloraSpacing.md) {
            MeloraArtworkImage(artworkPath: playlist.artworkPath, size: 56, cornerRadius: MeloraSpacing.radiusMedium)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: MeloraSpacing.xs) {
                    Text(playlist.title)
                        .font(MeloraTypography.bodyBold)
                        .foregroundColor(MeloraColors.textPrimary)
                        .lineLimit(1)

                    if playlist.isImportedFromSpotify {
                        Image(systemName: "wave.3.forward.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MeloraColors.spotifyGreen)
                    }
                }

                Text("\(playlist.trackCount) songs • \(playlist.durationFormatted)")
                    .font(MeloraTypography.caption)
                    .foregroundColor(MeloraColors.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, MeloraSpacing.xs)
    }
}

// MARK: - Playlist Detail View

public struct PlaylistDetailView: View {
    public let playlist: Playlist
    @Bindable public var viewModel: PlaylistViewModel
    @Bindable public var playerViewModel: PlayerViewModel

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: MeloraSpacing.xl) {
                // Artwork & Title Header
                VStack(spacing: MeloraSpacing.md) {
                    MeloraArtworkImage(
                        artworkPath: playlist.artworkPath,
                        size: 180,
                        cornerRadius: MeloraSpacing.radiusLarge
                    )
                    .shadow(color: MeloraColors.accent.opacity(0.12), radius: 16, x: 0, y: 8)

                    VStack(spacing: 4) {
                        Text(playlist.title)
                            .font(MeloraTypography.heroTitle)
                            .foregroundColor(MeloraColors.textPrimary)
                            .multilineTextAlignment(.center)

                        if let desc = playlist.description, !desc.isEmpty {
                            Text(desc)
                                .font(MeloraTypography.bodyRegular)
                                .foregroundColor(MeloraColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        Text("\(viewModel.selectedPlaylistTracks.count) tracks • \(playlist.durationFormatted)")
                            .font(MeloraTypography.caption)
                            .foregroundColor(MeloraColors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MeloraSpacing.md)

                // Play All & Shuffle Buttons
                HStack(spacing: MeloraSpacing.md) {
                    Button(action: {
                        if let first = viewModel.selectedPlaylistTracks.first {
                            playerViewModel.playTrack(first, queue: viewModel.selectedPlaylistTracks)
                        }
                    }) {
                        HStack(spacing: MeloraSpacing.sm) {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .font(MeloraTypography.bodyBold)
                        .foregroundColor(MeloraColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MeloraSpacing.md)
                        .background(MeloraColors.accent)
                        .clipShape(Capsule())
                    }

                    Button(action: {
                        if !viewModel.selectedPlaylistTracks.isEmpty {
                            var shuffled = viewModel.selectedPlaylistTracks
                            shuffled.shuffle()
                            playerViewModel.playTrack(shuffled[0], queue: shuffled)
                        }
                    }) {
                        HStack(spacing: MeloraSpacing.sm) {
                            Image(systemName: "shuffle")
                            Text("Shuffle")
                        }
                        .font(MeloraTypography.bodyBold)
                        .foregroundColor(MeloraColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MeloraSpacing.md)
                        .background(MeloraColors.cardElevated)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, MeloraSpacing.lg)

                // Tracks List
                if viewModel.selectedPlaylistTracks.isEmpty {
                    MeloraEmptyState(
                        systemImage: "music.note",
                        title: "No Tracks Added",
                        message: "Add songs to this playlist from your library."
                    )
                } else {
                    LazyVStack(spacing: MeloraSpacing.xs) {
                        ForEach(Array(viewModel.selectedPlaylistTracks.enumerated()), id: \.element.id) { index, track in
                            HStack(spacing: MeloraSpacing.md) {
                                Text("\(index + 1)")
                                    .font(MeloraTypography.timeIndicator)
                                    .foregroundColor(MeloraColors.textTertiary)
                                    .frame(width: 24, alignment: .trailing)

                                MeloraTrackRow(
                                    track: track,
                                    isPlaying: track.id == playerViewModel.currentTrack?.id,
                                    onPlay: {
                                        playerViewModel.playTrack(track, queue: viewModel.selectedPlaylistTracks)
                                    },
                                    onMoreAction: {
                                        viewModel.removeTrack(trackId: track.id, from: playlist.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, MeloraSpacing.lg)
                }
            }
            .padding(.bottom, 100)
        }
        .meloraBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadTracks(for: playlist)
        }
    }
}
#endif
