import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Screen 07 — Downloads / Local Storage: Storage inspection and sandboxed audio file management.
public struct DownloadsView: View {
    @Bindable public var viewModel: DownloadsViewModel
    @Bindable public var playerViewModel: PlayerViewModel

    public init(viewModel: DownloadsViewModel, playerViewModel: PlayerViewModel) {
        self.viewModel = viewModel
        self.playerViewModel = playerViewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MeloraSpacing.xl) {
                    // Storage Usage Summary Card
                    storageCard

                    // Formats Breakdown
                    if !viewModel.formatUsageBreakdown.isEmpty {
                        formatBreakdownSection
                    }

                    // Local Files List
                    localFilesSection
                }
                .padding(.horizontal, MeloraSpacing.lg)
                .padding(.bottom, 100)
            }
            .meloraBackground()
            .navigationTitle("Device Storage")
            .onAppear {
                viewModel.loadData()
            }
        }
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Storage Used")
                        .font(MeloraTypography.caption)
                        .foregroundColor(MeloraColors.textSecondary)

                    Text(viewModel.totalStorageFormatted)
                        .font(MeloraTypography.heroTitle)
                        .foregroundColor(MeloraColors.textPrimary)
                }

                Spacer()

                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 36))
                    .foregroundColor(MeloraColors.accent)
            }

            Text("\(viewModel.tracks.count) offline audio files in Melora sandbox")
                .font(MeloraTypography.caption)
                .foregroundColor(MeloraColors.textTertiary)
        }
        .meloraCard()
        .padding(.top, MeloraSpacing.sm)
    }

    private var formatBreakdownSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.sm) {
            Text("Storage by Codec")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MeloraSpacing.sm) {
                    ForEach(Array(viewModel.formatUsageBreakdown.keys), id: \.self) { format in
                        let bytes = viewModel.formatUsageBreakdown[format] ?? 0
                        let formatter = ByteCountFormatter()
                        let sizeStr = formatter.string(fromByteCount: bytes)

                        VStack(alignment: .leading, spacing: 4) {
                            MeloraFormatBadge(format: format)
                            Text(sizeStr)
                                .font(MeloraTypography.bodyBold)
                                .foregroundColor(MeloraColors.textPrimary)
                        }
                        .padding(MeloraSpacing.md)
                        .background(MeloraColors.cardElevated)
                        .clipShape(RoundedRectangle(cornerRadius: MeloraSpacing.radiusMedium, style: .continuous))
                    }
                }
            }
        }
    }

    private var localFilesSection: some View {
        VStack(alignment: .leading, spacing: MeloraSpacing.sm) {
            Text("Imported Tracks")
                .font(MeloraTypography.sectionHeader)
                .foregroundColor(MeloraColors.textPrimary)

            if viewModel.tracks.isEmpty {
                MeloraEmptyState(
                    systemImage: "folder",
                    title: "No Stored Files",
                    message: "No audio files have been imported into local storage yet."
                )
            } else {
                LazyVStack(spacing: MeloraSpacing.xs) {
                    ForEach(viewModel.tracks) { track in
                        HStack(spacing: MeloraSpacing.md) {
                            MeloraArtworkImage(artworkPath: track.artworkPath, size: 48)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(MeloraTypography.bodyBold)
                                    .foregroundColor(MeloraColors.textPrimary)
                                    .lineLimit(1)

                                HStack(spacing: MeloraSpacing.xs) {
                                    Text(track.fileSizeFormatted)
                                        .font(MeloraTypography.caption)
                                        .foregroundColor(MeloraColors.textSecondary)

                                    Text("•")
                                        .font(MeloraTypography.caption)
                                        .foregroundColor(MeloraColors.textTertiary)

                                    if let sr = track.sampleRate {
                                        Text("\(sr / 1000) kHz")
                                            .font(MeloraTypography.caption)
                                            .foregroundColor(MeloraColors.textTertiary)
                                    }
                                }
                            }

                            Spacer()

                            MeloraFormatBadge(format: track.audioFormat)

                            Button(role: .destructive, action: {
                                viewModel.deleteTrack(track)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(MeloraColors.danger.opacity(0.8))
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .padding(.vertical, MeloraSpacing.xs)
                    }
                }
            }
        }
    }
}
#endif
