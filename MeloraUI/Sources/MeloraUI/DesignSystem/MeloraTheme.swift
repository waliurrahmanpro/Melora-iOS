import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct MeloraCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = MeloraSpacing.radiusCard
    public var padding: CGFloat = MeloraSpacing.lg

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MeloraColors.darkCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MeloraColors.cardBorder, lineWidth: 1)
            )
    }
}

public struct MeloraBackgroundModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(MeloraColors.amoledBlack.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

public extension View {
    /// Applies Melora's true pitch black AMOLED background.
    func meloraBackground() -> some View {
        modifier(MeloraBackgroundModifier())
    }

    /// Applies Melora's standard card styling with dark surface and subtle border.
    func meloraCard(cornerRadius: CGFloat = MeloraSpacing.radiusCard, padding: CGFloat = MeloraSpacing.lg) -> some View {
        modifier(MeloraCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
#endif
