import Foundation
import MeloraCore
import MeloraData
import MeloraAudio
import MeloraUI

#if canImport(SwiftUI)
import SwiftUI

/// Main application entry point for Melora on iOS 18+.
@main
struct MeloraApp: App {
    @State private var playerViewModel: PlayerViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var searchViewModel: SearchViewModel
    @State private var libraryViewModel: LibraryViewModel
    @State private var spotifyViewModel: SpotifyViewModel
    @State private var settingsViewModel: SettingsViewModel

    init() {
        // 1. Initialize SQLite Database
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ??
                         URL(fileURLWithPath: NSTemporaryDirectory())
        let dbDir = appSupport.appendingPathComponent("Melora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbPath = dbDir.appendingPathComponent("melora.sqlite").path

        let database = try! SQLiteDatabase(databasePath: dbPath)
        try? database.migrate()

        // 2. Repositories
        let trackRepo = SQLiteTrackRepository(database: database)
        let playlistRepo = SQLitePlaylistRepository(database: database)
        let historyRepo = SQLitePlaybackHistoryRepository(database: database)

        // 3. Storage & Ingestion
        let storageManager = LocalFileStorageManager(baseStorageURL: dbDir)
        let metadataExtractor = AudioMetadataExtractor()
        let importService = LibraryImportService(
            storageManager: storageManager,
            metadataExtractor: metadataExtractor,
            trackRepository: trackRepo
        )
        let filterService = LibraryFilterService(
            trackRepository: trackRepo,
            storageManager: storageManager
        )

        // 4. Spotify Service
        let spotifyConfig = SpotifyAuthorizationConfiguration(
            clientId: "26cae7279c1742faa3d741dbdbb9fcb8",
            redirectUri: URL(string: "melora://spotify-callback")!
        )
        let tokenStorage = KeychainTokenStorage()
        let spotifyService = SpotifyService(
            configuration: spotifyConfig,
            tokenStorage: tokenStorage
        )

        // 5. Audio Engine & Background Playback Coordinator
        let audioEngine = AVFoundationAudioEngine(fileStorage: storageManager)
        let audioSessionManager = AudioSessionManager()
        let nowPlayingCoordinator = NowPlayingInfoCoordinator()
        let remoteCommandHandler = RemoteCommandHandler()

        let coordinator = AudioPlaybackCoordinator(
            audioEngine: audioEngine,
            audioSessionManager: audioSessionManager,
            nowPlayingCoordinator: nowPlayingCoordinator,
            remoteCommandHandler: remoteCommandHandler,
            historyRepository: historyRepo
        )

        // 6. ViewModels
        let pVM = PlayerViewModel(coordinator: coordinator)
        let hVM = HomeViewModel(trackRepository: trackRepo, playlistRepository: playlistRepo, historyRepository: historyRepo)
        let sVM = SearchViewModel(trackRepository: trackRepo, spotifyService: spotifyService)
        let lVM = LibraryViewModel(trackRepository: trackRepo, importService: importService, filterService: filterService)
        let spVM = SpotifyViewModel(spotifyService: spotifyService, playlistRepository: playlistRepo)
        let setVM = SettingsViewModel(historyRepository: historyRepo, spotifyService: spotifyService)

        _playerViewModel = State(initialValue: pVM)
        _homeViewModel = State(initialValue: hVM)
        _searchViewModel = State(initialValue: sVM)
        _libraryViewModel = State(initialValue: lVM)
        _spotifyViewModel = State(initialValue: spVM)
        _settingsViewModel = State(initialValue: setVM)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                playerViewModel: playerViewModel,
                homeViewModel: homeViewModel,
                searchViewModel: searchViewModel,
                libraryViewModel: libraryViewModel,
                spotifyViewModel: spotifyViewModel,
                settingsViewModel: settingsViewModel
            )
            .onOpenURL { url in
                spotifyViewModel.handleRedirectURL(url)
            }
        }
    }
}
#endif
