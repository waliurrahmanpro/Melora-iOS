import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Screen 02 — Search: Fast local library search with optional Spotify catalog metadata discovery.
public struct SearchView: View {
    @Bindable public var viewModel: SearchViewModel
    @Bindable public var playerViewModel: PlayerViewModel

    public init(viewModel: SearchViewModel, playerViewModel: PlayerViewModel) {
        self.viewModel = viewModel
        self.playerViewModel = playerViewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: MeloraSpacing.md) {
                // Search Input Field
                searchBar

                // Category Filter Pills
                categorySelector

                // Results Content
                if viewModel.isSearching {
                    ProgressView()
                        .tint(MeloraColors.accent)
                        .padding(.top, MeloraSpacing.xxxl)
                    Spacer()
                } else if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    initialPromptView
                } else if viewModel.localTracks.isEmpty && viewModel.localArtists.isEmpty && viewModel.localAlbums.isEmpty && viewModel.spotifyResults.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .meloraBackground()
            .navigationTitle("Search")
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: MeloraSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MeloraColors.textSecondary)

            TextField("Search songs, artists, albums...", text: $viewModel.query)
                .font(MeloraTypography.bodyRegular)
                .foregroundColor(MeloraColors.textPrimary)
                .autocorrectionDisabled()
                .onChange(of: viewModel.query) { _, _ in
                    viewModel.executeSearch()
                }

            if !viewModel.query.isEmpty {
                Button(action: {
                    viewModel.query = ""
                    viewModel.clearResults()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MeloraColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, MeloraSpacing.md)
        .padding(.vertical, MeloraSpacing.sm + 2)
        .background(MeloraColors.darkCard)
        .clipShape(RoundedRectangle(cornerRadius: MeloraSpacing.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MeloraSpacing.radiusMedium, style: .continuous)
                .stroke(MeloraColors.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, MeloraSpacing.lg)
        .padding(.top, MeloraSpacing.sm)
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MeloraSpacing.sm) {
                ForEach(SearchCategory.allCases) { category in
                    Button(action: {
                        viewModel.selectedCategory = category
                        viewModel.executeSearch()
                    }) {
                        Text(category.rawValue)
                            .font(MeloraTypography.bodyBold)
                            .foregroundColor(viewModel.selectedCategory == category ? MeloraColors.textPrimary : MeloraColors.textSecondary)
                            .padding(.horizontal, MeloraSpacing.md)
                            .padding(.vertical, 6)
                            .background(viewModel.selectedCategory == category ? MeloraColors.accent : MeloraColors.cardElevated)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, MeloraSpacing.lg)
        }
    }

    private var resultsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: MeloraSpacing.xl) {
                // Local Songs
                if (viewModel.selectedCategory == .all || viewModel.selectedCategory == .tracks) && !viewModel.localTracks.isEmpty {
                    VStack(alignment: .leading, spacing: MeloraSpacing.sm) {
                        Text("Songs")
                            .font(MeloraTypography.sectionHeader)
                            .foregroundColor(MeloraColors.textPrimary)

                        ForEach(viewModel.localTracks) { track in
                            MeloraTrackRow(
                                track: track,
                                isPlaying: track.id == playerViewModel.currentTrack?.id,
                                onPlay: {
                                    playerViewModel.playTrack(track, queue: viewModel.localTracks)
                                }
                            )
                        }
                    }
                }

                // Local Artists
                if (viewModel.selectedCategory == .all || viewModel.selectedCategory == .artists) && !viewModel.localArtists.isEmpty {
                    VStack(alignment: .leading, spacing: MeloraSpacing.sm) {
                        Text("Artists")
                            .font(MeloraTypography.sectionHeader)
                            .foregroundColor(MeloraColors.textPrimary)

                        ForEach(viewModel.localArtists, id: \.self) { artist in
                            HStack(spacing: MeloraSpacing.md) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(MeloraColors.accent)
                                Text(artist)
                                    .font(MeloraTypography.bodyBold)
                                    .foregroundColor(MeloraColors.textPrimary)
                                Spacer()
                            }
                            .padding(.vertical, MeloraSpacing.xs)
                        }
                    }
                }

                // Spotify Online Results (Discovery)
                if (viewModel.selectedCategory == .all || viewModel.selectedCategory == .spotify) && !viewModel.spotifyResults.isEmpty {
                    VStack(alignment: .leading, spacing: MeloraSpacing.sm) {
                        HStack(spacing: MeloraSpacing.xs) {
                            Image(systemName: "waveform.badge.magnifyingglass")
                                .foregroundColor(MeloraColors.spotifyGreen)
                            Text("Spotify Discovery (Metadata)")
                                .font(MeloraTypography.sectionHeader)
                                .foregroundColor(MeloraColors.textPrimary)
                        }

                        ForEach(viewModel.spotifyResults) { remoteTrack in
                            HStack(spacing: MeloraSpacing.md) {
                                MeloraArtworkImage(artworkPath: remoteTrack.artworkUrl, size: 48)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(remoteTrack.title)
                                        .font(MeloraTypography.bodyBold)
                                        .foregroundColor(MeloraColors.textPrimary)
                                        .lineLimit(1)

                                    Text(remoteTrack.artistName)
                                        .font(MeloraTypography.caption)
                                        .foregroundColor(MeloraColors.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text("Online")
                                    .font(MeloraTypography.badge)
                                    .foregroundColor(MeloraColors.spotifyGreen)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(MeloraColors.cardElevated)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, MeloraSpacing.xs)
                        }
                    }
                }
            }
            .padding(.horizontal, MeloraSpacing.lg)
            .padding(.bottom, 100)
        }
    }

    private var initialPromptView: some View {
        MeloraEmptyState(
            systemImage: "magnifyingglass",
            title: "Search Your Music",
            message: "Find songs, artists, and albums in your local library."
        )
    }

    private var noResultsView: some View {
        MeloraEmptyState(
            systemImage: "questionmark.folder",
            title: "No Results Found",
            message: "No matching tracks or artists were found for '\(viewModel.query)'."
        )
    }
}
#endif
