import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Screen 06 — Spotify: Authorized metadata discovery and playlist ingestion.
public struct SpotifyView: View {
    @Bindable public var viewModel: SpotifyViewModel

    public init(viewModel: SpotifyViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MeloraSpacing.xxl) {
                    if !viewModel.isAuthenticated {
                        connectCard
                    } else {
                        connectedProfileCard
                        remotePlaylistsSection
                    }

                    if !viewModel.importedPlaylists.isEmpty {
                        importedSection
                    }

                    complianceCard
                }
                .padding(.horizontal, MeloraSpacing.lg)
                .padding(.bottom, 100)
            }
            .meloraBackground()
            .navigationTitle("Spotify Integration")
            .onAppear {
                viewModel.checkAuthAndLoad()
            }
        }
    }

    // MARK: - Subviews

    private var connectCard: some View {
        VStack(spacing: MeloraSpacing.lg) {
            Image(systemName: "wave.3.forward.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(MeloraColors.spotifyGreen)

            VStack(spacing: MeloraSpacing.xs) {
                Text("Connect Spotify")
                    .font(MeloraTypography.heroTitle)
                    .foregroundColor(MeloraColors.textPrimary)

                Text("Sync your playlists, discover artist metadata, and match tracks with your local audio collection.")
                    .font(MeloraTypography.bodyRegular)
                    .foregroundColor(MeloraColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { viewModel.initiateLogin() }) {
                HStack(spacing: MeloraSpacing.sm) {
                    if viewModel.isConnecting {
                        ProgressView().tint(MeloraColors.amoledBlack)
                    } else {
                        Image(systemName: "link")
                        Text("Connect with Spotify")
                    }
                }
                .font(MeloraTypography.bodyBold)
                .foregroundColor(MeloraColors.amoledBlack)
                .padding(.horizontal, MeloraSpacing.xl)
                .padding(.vertical, MeloraSpacing.md)
                .background(MeloraColors.spotifyGreen)
                .clipShape(Capsule())
            }
            .disabled(viewModel.isConnecting)
        }
        .meloraCard()
        .padding(.top, MeloraSpacing.md)
    }

    private var connectedProfileCard: some View {
        HStack(spacing: MeloraSpacing.md) {
            Image(systemName: "wave.3.forward.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(MeloraColors.spotifyGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("Spotify Connected")
                    .font(MeloraTypography.bodyBold)
                    .foregroundColor(MeloraColors.textPrimary)

                Text("Authorized via OAuth 2.0 PKCE")
                    .font(MeloraTypography.caption)
                    .foregroundColor(MeloraColors.spotifyGreen)
            }

            Spacer()

            Button("Disconnect") {
                viewModel.disconnect()
            }
            .font(MeloraTypography.captionMedium)
            .foregroundColor(MeloraColors.danger)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(MeloraColors.cardElevated)
            .clipShape(Capsule())
        }
        .meloraCard()
    }

    private var remotePlaylistsSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.md) {
            Text("Spotify Playlists")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            if viewModel.remotePlaylists.isEmpty {
                ProgressView().tint(MeloraColors.spotifyGreen)
            } else {
                VStack(spacing: MeloraSpacing.sm) {
                    ForEach(viewModel.remotePlaylists) { item in
                        HStack(spacing: MeloraSpacing.md) {
                            MeloraArtworkImage(artworkPath: item.artworkUrl, size: 52)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(MeloraTypography.bodyBold)
                                    .foregroundColor(MeloraColors.textPrimary)
                                    .lineLimit(1)

                                Text("\(item.totalTracks) tracks")
                                    .font(MeloraTypography.caption)
                                    .foregroundColor(MeloraColors.textSecondary)
                            }

                            Spacer()

                            Button(action: {
                                viewModel.importSpotifyPlaylistMetadata(item)
                            }) {
                                Text("Import")
                                    .font(MeloraTypography.captionMedium)
                                    .foregroundColor(MeloraColors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(MeloraColors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, MeloraSpacing.xs)
                    }
                }
            }
        }
    }

    private var importedSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.md) {
            Text("Imported Playlists")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            VStack(spacing: MeloraSpacing.sm) {
                ForEach(viewModel.importedPlaylists) { pl in
                    HStack(spacing: MeloraSpacing.md) {
                        MeloraArtworkImage(artworkPath: pl.artworkPath, size: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pl.title)
                                .font(MeloraTypography.bodyBold)
                                .foregroundColor(MeloraColors.textPrimary)

                            Text("\(pl.trackCount) tracks in Melora")
                                .font(MeloraTypography.caption)
                                .foregroundColor(MeloraColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(MeloraColors.success)
                    }
                    .padding(.vertical, MeloraSpacing.xs)
                }
            }
        }
    }

    private var complianceCard: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.xs) {
            HStack(spacing: MeloraSpacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(MeloraColors.accent)
                Text("Spotify Developer Terms Compliance")
                    .font(MeloraTypography.captionMedium)
                    .foregroundColor(MeloraColors.textPrimary)
            }

            Text("Melora uses official Spotify Web APIs for user playlists, saved items, and music metadata. Audio playback is supported exclusively for your local audio files. Melora does not extract or stream copyrighted Spotify audio.")
                .font(MeloraTypography.caption)
                .foregroundColor(MeloraColors.textTertiary)
        }
        .meloraCard(padding: MeloraSpacing.md)
    }
}
#endif
