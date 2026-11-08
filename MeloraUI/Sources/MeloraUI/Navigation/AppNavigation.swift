import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Main bottom navigation tab options.
public enum MeloraTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case search
    case library
    case spotify
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .library: return "Library"
        case .spotify: return "Spotify"
        case .settings: return "Settings"
        }
    }

    public var systemIcon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .library: return "books.vertical.fill"
        case .spotify: return "wave.3.forward.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
#endif
