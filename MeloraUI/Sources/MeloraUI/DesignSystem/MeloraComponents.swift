import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Artwork Image Loader

public struct MeloraArtworkImage: View {
    public let artworkPath: String?
    public let size: CGFloat
    public var cornerRadius: CGFloat = MeloraSpacing.radiusMedium

    public init(artworkPath: String?, size: CGFloat = 56, cornerRadius: CGFloat = MeloraSpacing.radiusMedium) {
        self.artworkPath = artworkPath
        self.size = size
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            if let path = artworkPath, !path.isEmpty {
                if path.hasPrefix("http://") || path.hasPrefix("https://") {
                    AsyncImage(url: URL(string: path)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            placeholderView
                        }
                    }
                } else {
                    localImageView(path: path)
                }
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(MeloraColors.cardBorder.opacity(0.6), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func localImageView(path: String) -> some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            placeholderView
        }
        #elseif canImport(AppKit)
        if let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            placeholderView
        }
        #else
        placeholderView
        #endif
    }

    private var placeholderView: some View {
        ZStack {
            MeloraColors.cardElevated
            Image(systemName: "music.note")
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(MeloraColors.textSecondary)
        }
    }
}

// MARK: - Audio Format Badge

public struct MeloraFormatBadge: View {
    public let format: AudioFormat

    public init(format: AudioFormat) {
        self.format = format
    }

    public var body: some View {
        Text(format.rawValue.uppercased())
            .font(MeloraTypography.badge)
            .foregroundColor(format.isLossless ? MeloraColors.accent : MeloraColors.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(format.isLossless ? MeloraColors.accentSubtle : MeloraColors.cardElevated)
            )
            .overlay(
                Capsule()
                    .stroke(format.isLossless ? MeloraColors.accent.opacity(0.4) : MeloraColors.cardBorder, lineWidth: 1)
            )
    }
}

// MARK: - Accessible Icon Button

public struct MeloraIconButton: View {
    public let systemName: String
    public let size: CGFloat
    public let color: Color
    public let accessibilityLabelText: String
    public let action: () -> Void

    public init(
        systemName: String,
        size: CGFloat = 20,
        color: Color = MeloraColors.textPrimary,
        accessibilityLabelText: String,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.size = size
        self.color = color
        self.accessibilityLabelText = accessibilityLabelText
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(color)
                .frame(width: max(size + 24, MeloraSpacing.minimumTouchTarget),
                       height: max(size + 24, MeloraSpacing.minimumTouchTarget))
                .contentShape(Rectangle())
        }
        .accessibilityLabel(accessibilityLabelText)
    }
}

// MARK: - Reusable Track Row

public struct MeloraTrackRow: View {
    public let track: Track
    public let isPlaying: Bool
    public let onPlay: () -> Void
    public var onMoreAction: (() -> Void)? = nil

    public init(
        track: Track,
        isPlaying: Bool = false,
        onPlay: @escaping () -> Void,
        onMoreAction: (() -> Void)? = nil
    ) {
        self.track = track
        self.isPlaying = isPlaying
        self.onPlay = onPlay
        self.onMoreAction = onMoreAction
    }

    public var body: some View {
        HStack(spacing: MeloraSpacing.md) {
            Button(action: onPlay) {
                HStack(spacing: MeloraSpacing.md) {
                    MeloraArtworkImage(artworkPath: track.artworkPath, size: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(MeloraTypography.bodyBold)
                            .foregroundColor(isPlaying ? MeloraColors.accent : MeloraColors.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: MeloraSpacing.xs) {
                            Text(track.artistName)
                                .font(MeloraTypography.caption)
                                .foregroundColor(MeloraColors.textSecondary)
                                .lineLimit(1)

                            Text("•")
                                .font(MeloraTypography.caption)
                                .foregroundColor(MeloraColors.textTertiary)

                            Text(track.durationFormatted)
                                .font(MeloraTypography.caption)
                                .foregroundColor(MeloraColors.textTertiary)
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(track.title) by \(track.artistName), duration \(track.durationFormatted)")
            .accessibilityHint("Double tap to play")

            MeloraFormatBadge(format: track.audioFormat)

            if let onMore = onMoreAction {
                MeloraIconButton(
                    systemName: "ellipsis",
                    size: 16,
                    color: MeloraColors.textSecondary,
                    accessibilityLabelText: "More options for \(track.title)",
                    action: onMore
                )
            }
        }
        .padding(.vertical, MeloraSpacing.xs)
    }
}

// MARK: - Empty State View

public struct MeloraEmptyState: View {
    public let systemImage: String
    public let title: String
    public let message: String
    public var buttonTitle: String? = nil
    public var buttonAction: (() -> Void)? = nil

    public init(
        systemImage: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    public var body: some View {
        VStack(spacing: MeloraSpacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(MeloraColors.accent.opacity(0.8))

            VStack(spacing: MeloraSpacing.xs) {
                Text(title)
                    .font(MeloraTypography.sectionHeader)
                    .foregroundColor(MeloraColors.textPrimary)

                Text(message)
                    .font(MeloraTypography.bodyRegular)
                    .foregroundColor(MeloraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MeloraSpacing.xl)
            }

            if let btn = buttonTitle, let action = buttonAction {
                Button(action: action) {
                    Text(btn)
                        .font(MeloraTypography.bodyBold)
                        .foregroundColor(MeloraColors.textPrimary)
                        .padding(.horizontal, MeloraSpacing.xl)
                        .padding(.vertical, MeloraSpacing.md)
                        .background(MeloraColors.accent)
                        .clipShape(Capsule())
                }
                .padding(.top, MeloraSpacing.sm)
            }
        }
        .padding(MeloraSpacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
