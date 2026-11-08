import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Layout spacing and corner radius design tokens.
public enum MeloraSpacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let huge: CGFloat = 48

    // Corner Radii
    public static let radiusSmall: CGFloat = 8
    public static let radiusMedium: CGFloat = 12
    public static let radiusCard: CGFloat = 16
    public static let radiusLarge: CGFloat = 20
    public static let radiusPill: CGFloat = 999

    // Minimum accessible touch target (Apple HIG)
    public static let minimumTouchTarget: CGFloat = 44
}
#endif
