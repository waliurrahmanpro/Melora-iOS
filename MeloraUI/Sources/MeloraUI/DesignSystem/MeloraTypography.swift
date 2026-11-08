import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Standardized typography scale with Dynamic Type support.
public enum MeloraTypography {
    public static let heroTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    public static let screenTitle = Font.system(size: 22, weight: .bold, design: .default)
    public static let sectionHeader = Font.system(size: 18, weight: .semibold, design: .default)
    public static let itemTitle = Font.system(size: 16, weight: .semibold, design: .default)
    public static let bodyBold = Font.system(size: 15, weight: .semibold, design: .default)
    public static let bodyRegular = Font.system(size: 15, weight: .regular, design: .default)
    public static let caption = Font.system(size: 13, weight: .regular, design: .default)
    public static let captionMedium = Font.system(size: 13, weight: .medium, design: .default)
    public static let badge = Font.system(size: 11, weight: .bold, design: .rounded)
    public static let timeIndicator = Font.system(size: 12, weight: .medium, design: .monospaced)
}
#endif
