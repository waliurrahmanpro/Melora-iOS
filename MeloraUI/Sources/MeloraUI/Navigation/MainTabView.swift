import Foundation
import MeloraCore
import MeloraData
import MeloraAudio

#if canImport(SwiftUI)
import SwiftUI

/// Root tab navigation view hosting the 5 primary tabs, persistent mini player, and full Now Playing modal.
public struct MainTabView: View {
    @State private var selectedTab: MeloraTab = .home

    @Bindable public var playerViewModel: PlayerViewModel
    @Bindable public var homeViewModel: HomeViewModel
    @Bindable public var searchViewModel: SearchViewModel
    @Bindable public var libraryViewModel: LibraryViewModel
    @Bindable public var spotifyViewModel: SpotifyViewModel
    @Bindable public var settingsViewModel: SettingsViewModel

    public init(
        playerViewModel: PlayerViewModel,
        homeViewModel: HomeViewModel,
        searchViewModel: SearchViewModel,
        libraryViewModel: LibraryViewModel,
        spotifyViewModel: SpotifyViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.playerViewModel = playerViewModel
        self.homeViewModel = homeViewModel
        self.searchViewModel = searchViewModel
        self.libraryViewModel = libraryViewModel
        self.spotifyViewModel = spotifyViewModel
        self.settingsViewModel = settingsViewModel
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                    viewModel: homeViewModel,
                    playerViewModel: playerViewModel,
                    onNavigateToSearch: { selectedTab = .search }
                )
                .tabItem {
                    Label(MeloraTab.home.title, systemImage: MeloraTab.home.systemIcon)
                }
                .tag(MeloraTab.home)

                SearchView(
                    viewModel: searchViewModel,
                    playerViewModel: playerViewModel
                )
                .tabItem {
                    Label(MeloraTab.search.title, systemImage: MeloraTab.search.systemIcon)
                }
                .tag(MeloraTab.search)

                LibraryView(
                    viewModel: libraryViewModel,
                    playerViewModel: playerViewModel
                )
                .tabItem {
                    Label(MeloraTab.library.title, systemImage: MeloraTab.library.systemIcon)
                }
                .tag(MeloraTab.library)

                SpotifyView(
                    viewModel: spotifyViewModel
                )
                .tabItem {
                    Label(MeloraTab.spotify.title, systemImage: MeloraTab.spotify.systemIcon)
                }
                .tag(MeloraTab.spotify)

                SettingsView(
                    viewModel: settingsViewModel
                )
                .tabItem {
                    Label(MeloraTab.settings.title, systemImage: MeloraTab.settings.systemIcon)
                }
                .tag(MeloraTab.settings)
            }
            .tint(MeloraColors.accent)

            // Persistent Floating Mini Player
            if playerViewModel.currentTrack != nil {
                MiniPlayerView(viewModel: playerViewModel)
                    .padding(.bottom, 54) // Position above tab bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $playerViewModel.isNowPlayingPresented) {
            NowPlayingView(viewModel: playerViewModel)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
