import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Premium AMOLED Dark Color Palette for Melora.
public enum MeloraColors {
    /// Pure pitch black for true AMOLED display power efficiency (#000000).
    public static let amoledBlack = Color(red: 0.0, green: 0.0, blue: 0.0)

    /// Dark charcoal for base card surfaces (#121212).
    public static let darkCard = Color(red: 0.07, green: 0.07, blue: 0.07)

    /// Elevated card surface for popups, modals, and sheets (#1C1C1E).
    public static let cardElevated = Color(red: 0.11, green: 0.11, blue: 0.12)

    /// Ultra-subtle border for card elevation boundaries (#27272A).
    public static let cardBorder = Color(red: 0.15, green: 0.15, blue: 0.16)

    /// Vibrant Melora violet accent color (#8B5CF6).
    public static let accent = Color(red: 0.55, green: 0.36, blue: 0.96)

    /// Subtle background wash for active states and badges.
    public static let accentSubtle = accent.opacity(0.18)

    /// High-contrast primary text (#FFFFFF).
    public static let textPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)

    /// Secondary supporting text (#A1A1AA / Zinc 400).
    public static let textSecondary = Color(red: 0.63, green: 0.63, blue: 0.67)

    /// Tertiary muted caption text (#71717A / Zinc 500).
    public static let textTertiary = Color(red: 0.44, green: 0.44, blue: 0.48)

    /// Emerald success color (#10B981).
    public static let success = Color(red: 0.06, green: 0.73, blue: 0.51)

    /// Rose danger / destructive action color (#EF4444).
    public static let danger = Color(red: 0.94, green: 0.27, blue: 0.27)

    /// Warning amber color (#F59E0B).
    public static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)

    /// Spotify brand green for authentic integration indicators (#1DB954).
    public static let spotifyGreen = Color(red: 0.11, green: 0.73, blue: 0.33)
}
#endif
