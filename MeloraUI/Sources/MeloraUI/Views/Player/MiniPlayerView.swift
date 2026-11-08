import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Persistent mini player floating above the bottom tab bar when playback is active.
public struct MiniPlayerView: View {
    @Bindable public var viewModel: PlayerViewModel

    public init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if let track = viewModel.currentTrack {
            VStack(spacing: 0) {
                // Micro progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(MeloraColors.cardBorder)
                            .frame(height: 2)
                        Rectangle()
                            .fill(MeloraColors.accent)
                            .frame(width: geo.size.width * CGFloat(viewModel.position.progress), height: 2)
                    }
                }
                .frame(height: 2)

                HStack(spacing: MeloraSpacing.md) {
                    MeloraArtworkImage(artworkPath: track.artworkPath, size: 42, cornerRadius: MeloraSpacing.radiusSmall)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(MeloraTypography.bodyBold)
                            .foregroundColor(MeloraColors.textPrimary)
                            .lineLimit(1)

                        Text(track.artistName)
                            .font(MeloraTypography.caption)
                            .foregroundColor(MeloraColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Play/Pause button
                    MeloraIconButton(
                        systemName: viewModel.status.isPlaying ? "pause.fill" : "play.fill",
                        size: 18,
                        color: MeloraColors.textPrimary,
                        accessibilityLabelText: viewModel.status.isPlaying ? "Pause" : "Play"
                    ) {
                        viewModel.togglePlayPause()
                    }

                    // Next track button
                    MeloraIconButton(
                        systemName: "forward.fill",
                        size: 16,
                        color: MeloraColors.textSecondary,
                        accessibilityLabelText: "Next track"
                    ) {
                        viewModel.skipToNext()
                    }
                }
                .padding(.horizontal, MeloraSpacing.lg)
                .padding(.vertical, MeloraSpacing.sm)
            }
            .background(MeloraColors.cardElevated)
            .clipShape(RoundedRectangle(cornerRadius: MeloraSpacing.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MeloraSpacing.radiusCard, style: .continuous)
                    .stroke(MeloraColors.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, MeloraSpacing.sm)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.isNowPlayingPresented = true
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Now playing: \(track.title) by \(track.artistName)")
            .accessibilityHint("Double tap to open now playing screen")
        }
    }
}
#endif
