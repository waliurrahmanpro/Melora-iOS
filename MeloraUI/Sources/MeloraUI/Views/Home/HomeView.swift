import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Screen 01 — Home: Personalized dashboard with real database feeds and quick actions.
public struct HomeView: View {
    @Bindable public var viewModel: HomeViewModel
    @Bindable public var playerViewModel: PlayerViewModel
    public var onNavigateToSearch: () -> Void

    public init(
        viewModel: HomeViewModel,
        playerViewModel: PlayerViewModel,
        onNavigateToSearch: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.playerViewModel = playerViewModel
        self.onNavigateToSearch = onNavigateToSearch
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: MeloraSpacing.xxl) {
                    // Header Bar
                    headerSection

                    if viewModel.recentlyAddedTracks.isEmpty && viewModel.playlists.isEmpty {
                        emptyLibraryPrompt
                    } else {
                        // Continue Listening / Recently Played
                        if !viewModel.recentlyPlayedTracks.isEmpty {
                            recentlyPlayedSection
                        }

                        // Recently Added
                        recentlyAddedSection

                        // Top Artists
                        if !viewModel.topArtists.isEmpty {
                            topArtistsSection
                        }

                        // Playlists
                        if !viewModel.playlists.isEmpty {
                            playlistsSection
                        }
                    }
                }
                .padding(.horizontal, MeloraSpacing.lg)
                .padding(.bottom, 100) // Padding for MiniPlayer
            }
            .meloraBackground()
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(MeloraTypography.heroTitle)
                    .foregroundColor(MeloraColors.textPrimary)

                Text("Welcome to Melora")
                    .font(MeloraTypography.bodyRegular)
                    .foregroundColor(MeloraColors.textSecondary)
            }

            Spacer()

            MeloraIconButton(
                systemName: "magnifyingglass",
                size: 20,
                color: MeloraColors.textPrimary,
                accessibilityLabelText: "Search library"
            ) {
                onNavigateToSearch()
            }
        }
        .padding(.top, MeloraSpacing.md)
    }

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.md) {
            Text("Recently Played")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MeloraSpacing.md) {
                    ForEach(viewModel.recentlyPlayedTracks) { track in
                        Button(action: {
                            playerViewModel.playTrack(track, queue: viewModel.recentlyPlayedTracks)
                        }) {
                            VStack(alignment: .leading, spacing: MeloraSpacing.xs) {
                                MeloraArtworkImage(artworkPath: track.artworkPath, size: 120, cornerRadius: MeloraSpacing.radiusMedium)

                                Text(track.title)
                                    .font(MeloraTypography.bodyBold)
                                    .foregroundColor(MeloraColors.textPrimary)
                                    .lineLimit(1)
                                    .frame(width: 120, alignment: .leading)

                                Text(track.artistName)
                                    .font(MeloraTypography.caption)
                                    .foregroundColor(MeloraColors.textSecondary)
                                    .lineLimit(1)
                                    .frame(width: 120, alignment: .leading)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.md) {
            Text("Recently Added")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            VStack(spacing: MeloraSpacing.xs) {
                ForEach(viewModel.recentlyAddedTracks.prefix(5)) { track in
                    MeloraTrackRow(
                        track: track,
                        isPlaying: track.id == playerViewModel.currentTrack?.id,
                        onPlay: {
                            playerViewModel.playTrack(track, queue: viewModel.recentlyAddedTracks)
                        }
                    )
                }
            }
        }
    }

    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.md) {
            Text("Popular Artists")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MeloraSpacing.sm) {
                    ForEach(viewModel.topArtists, id: \.self) { artist in
                        HStack(spacing: MeloraSpacing.xs) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(MeloraColors.accent)
                            Text(artist)
                                .font(MeloraTypography.bodyBold)
                                .foregroundColor(MeloraColors.textPrimary)
                        }
                        .padding(.horizontal, MeloraSpacing.md)
                        .padding(.vertical, MeloraSpacing.sm)
                        .background(MeloraColors.cardElevated)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.md) {
            Text("Your Playlists")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MeloraSpacing.md) {
                    ForEach(viewModel.playlists) { playlist in
                        VStack(alignment: .leading, spacing: MeloraSpacing.xs) {
                            MeloraArtworkImage(artworkPath: playlist.artworkPath, size: 130, cornerRadius: MeloraSpacing.radiusMedium)

                            Text(playlist.title)
                                .font(MeloraTypography.bodyBold)
                                .foregroundColor(MeloraColors.textPrimary)
                                .lineLimit(1)
                                .frame(width: 130, alignment: .leading)

                            Text("\(playlist.trackCount) songs")
                                .font(MeloraTypography.caption)
                                .foregroundColor(MeloraColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var emptyLibraryPrompt: some View {
        MeloraEmptyState(
            systemImage: "music.note.house",
            title: "Your Library is Empty",
            message: "Import your local music files (MP3, FLAC, M4A, WAV) in the Library tab to start listening."
        )
        .padding(.top, MeloraSpacing.huge)
    }
}
#endif
