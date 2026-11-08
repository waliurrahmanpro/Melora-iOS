import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Fullscreen Now Playing screen with large artwork, scrub slider, and playback controls.
public struct NowPlayingView: View {
    @Bindable public var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isDraggingScrubber = false
    @State private var scrubPositionSeconds: Double = 0.0

    public init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            MeloraColors.amoledBlack.ignoresSafeArea()

            if let track = viewModel.currentTrack {
                VStack(spacing: MeloraSpacing.lg) {
                    // Top Bar: Dismiss Chevron & Queue Button
                    HStack {
                        MeloraIconButton(
                            systemName: "chevron.down",
                            size: 18,
                            color: MeloraColors.textSecondary,
                            accessibilityLabelText: "Dismiss now playing"
                        ) {
                            dismiss()
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("PLAYING FROM LIBRARY")
                                .font(MeloraTypography.badge)
                                .foregroundColor(MeloraColors.textTertiary)
                                .tracking(1)

                            if let album = track.albumTitle {
                                Text(album)
                                    .font(MeloraTypography.captionMedium)
                                    .foregroundColor(MeloraColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        MeloraIconButton(
                            systemName: "list.bullet",
                            size: 18,
                            color: MeloraColors.textSecondary,
                            accessibilityLabelText: "View playback queue"
                        ) {
                            viewModel.isQueuePresented = true
                        }
                    }
                    .padding(.horizontal, MeloraSpacing.lg)
                    .padding(.top, MeloraSpacing.sm)

                    Spacer(minLength: MeloraSpacing.sm)

                    // Hero Album Artwork
                    GeometryReader { geo in
                        let artworkSize = min(geo.size.width - MeloraSpacing.huge * 2, 340)
                        MeloraArtworkImage(
                            artworkPath: track.artworkPath,
                            size: artworkSize,
                            cornerRadius: MeloraSpacing.radiusLarge
                        )
                        .shadow(color: MeloraColors.accent.opacity(0.15), radius: 24, x: 0, y: 12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 320)

                    Spacer(minLength: MeloraSpacing.sm)

                    // Track Title & Favorite Button
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: MeloraSpacing.xs) {
                            Text(track.title)
                                .font(MeloraTypography.heroTitle)
                                .foregroundColor(MeloraColors.textPrimary)
                                .lineLimit(1)

                            HStack(spacing: MeloraSpacing.sm) {
                                Text(track.artistName)
                                    .font(MeloraTypography.sectionHeader)
                                    .foregroundColor(MeloraColors.textSecondary)
                                    .lineLimit(1)

                                MeloraFormatBadge(format: track.audioFormat)
                            }
                        }

                        Spacer()

                        MeloraIconButton(
                            systemName: viewModel.isFavorite ? "heart.fill" : "heart",
                            size: 22,
                            color: viewModel.isFavorite ? MeloraColors.danger : MeloraColors.textSecondary,
                            accessibilityLabelText: viewModel.isFavorite ? "Remove from favorites" : "Add to favorites"
                        ) {
                            viewModel.toggleFavorite()
                        }
                    }
                    .padding(.horizontal, MeloraSpacing.xl)

                    // Interactive Scrub Slider
                    VStack(spacing: MeloraSpacing.xs) {
                        let activeSeconds = isDraggingScrubber ? scrubPositionSeconds : viewModel.position.currentTimeSeconds
                        let totalSeconds = max(track.durationSeconds, 1.0)
                        let progress = min(max(activeSeconds / totalSeconds, 0.0), 1.0)

                        GeometryReader { sliderGeo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(MeloraColors.cardElevated)
                                    .frame(height: 6)

                                Capsule()
                                    .fill(MeloraColors.accent)
                                    .frame(width: sliderGeo.size.width * CGFloat(progress), height: 6)

                                Circle()
                                    .fill(MeloraColors.textPrimary)
                                    .frame(width: 14, height: 14)
                                    .offset(x: max(0, sliderGeo.size.width * CGFloat(progress) - 7))
                            }
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        isDraggingScrubber = true
                                        let dragFraction = min(max(value.location.x / sliderGeo.size.width, 0.0), 1.0)
                                        scrubPositionSeconds = dragFraction * totalSeconds
                                    }
                                    .onEnded { value in
                                        let dragFraction = min(max(value.location.x / sliderGeo.size.width, 0.0), 1.0)
                                        let target = dragFraction * totalSeconds
                                        viewModel.seek(toSeconds: target)
                                        isDraggingScrubber = false
                                    }
                            )
                        }
                        .frame(height: 18)

                        // Time Labels
                        HStack {
                            Text(formatSeconds(activeSeconds))
                                .font(MeloraTypography.timeIndicator)
                                .foregroundColor(MeloraColors.textTertiary)

                            Spacer()

                            Text("-" + formatSeconds(max(0, totalSeconds - activeSeconds)))
                                .font(MeloraTypography.timeIndicator)
                                .foregroundColor(MeloraColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, MeloraSpacing.xl)

                    // Main Playback Controls
                    HStack(spacing: MeloraSpacing.xl) {
                        // Shuffle Mode
                        MeloraIconButton(
                            systemName: "shuffle",
                            size: 20,
                            color: viewModel.shuffleMode == .on ? MeloraColors.accent : MeloraColors.textSecondary,
                            accessibilityLabelText: "Shuffle: \(viewModel.shuffleMode.rawValue)"
                        ) {
                            viewModel.toggleShuffle()
                        }

                        Spacer()

                        // Previous Track
                        MeloraIconButton(
                            systemName: "backward.fill",
                            size: 26,
                            color: MeloraColors.textPrimary,
                            accessibilityLabelText: "Previous track"
                        ) {
                            viewModel.skipToPrevious()
                        }

                        Spacer()

                        // Big Play/Pause Button
                        Button(action: { viewModel.togglePlayPause() }) {
                            ZStack {
                                Circle()
                                    .fill(MeloraColors.textPrimary)
                                    .frame(width: 68, height: 68)

                                Image(systemName: viewModel.status.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(MeloraColors.amoledBlack)
                                    .offset(x: viewModel.status.isPlaying ? 0 : 2)
                            }
                        }
                        .accessibilityLabel(viewModel.status.isPlaying ? "Pause" : "Play")

                        Spacer()

                        // Next Track
                        MeloraIconButton(
                            systemName: "forward.fill",
                            size: 26,
                            color: MeloraColors.textPrimary,
                            accessibilityLabelText: "Next track"
                        ) {
                            viewModel.skipToNext()
                        }

                        Spacer()

                        // Repeat Mode
                        MeloraIconButton(
                            systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat",
                            size: 20,
                            color: viewModel.repeatMode != .off ? MeloraColors.accent : MeloraColors.textSecondary,
                            accessibilityLabelText: "Repeat: \(viewModel.repeatMode.rawValue)"
                        ) {
                            viewModel.cycleRepeatMode()
                        }
                    }
                    .padding(.horizontal, MeloraSpacing.xl)

                    Spacer(minLength: MeloraSpacing.md)
                }
            } else {
                MeloraEmptyState(
                    systemImage: "music.note",
                    title: "Nothing Playing",
                    message: "Select a song from your local library to start listening."
                )
            }
        }
        .sheet(isPresented: $viewModel.isQueuePresented) {
            QueueSheetView(viewModel: viewModel)
        }
    }

    private func formatSeconds(_ seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Queue Sheet View

public struct QueueSheetView: View {
    @Bindable public var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                MeloraColors.amoledBlack.ignoresSafeArea()

                if viewModel.queue.isEmpty {
                    MeloraEmptyState(
                        systemImage: "list.bullet",
                        title: "Queue is Empty",
                        message: "Add tracks from your library to populate the queue."
                    )
                } else {
                    List {
                        ForEach(viewModel.queue) { track in
                            MeloraTrackRow(
                                track: track,
                                isPlaying: track.id == viewModel.currentTrack?.id,
                                onPlay: {
                                    viewModel.playTrack(track, queue: viewModel.queue)
                                }
                            )
                            .listRowBackground(MeloraColors.amoledBlack)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Up Next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(MeloraColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
