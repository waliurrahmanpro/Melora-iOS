import Foundation
import MeloraCore

/// Master Spotify service implementation uniting OAuth and REST services.
///
/// Fully conforms to SpotifyServiceProtocol from MeloraCore.
/// Strictly respects Spotify Developer Terms: metadata discovery, search, and playlist ingestion only.
public final class SpotifyService: SpotifyServiceProtocol, @unchecked Sendable {
    public let oauthManager: SpotifyOAuthManager
    public let apiClient: SpotifyAPIClientProtocol
    public let profileService: SpotifyProfileService
    public let playlistService: SpotifyPlaylistService
    public let libraryService: SpotifyLibraryService
    public let searchService: SpotifySearchService
    public let metadataService: SpotifyMetadataService

    private let tokenStorage: SecureTokenStorageProtocol

    public init(
        configuration: SpotifyAuthorizationConfiguration,
        tokenStorage: SecureTokenStorageProtocol,
        urlSession: URLSession = .shared
    ) {
        self.tokenStorage = tokenStorage
        let oauth = SpotifyOAuthManager(
            configuration: configuration,
            tokenStorage: tokenStorage,
            urlSession: urlSession
        )
        let client = SpotifyAPIClient(
            tokenManager: oauth.tokenManager,
            urlSession: urlSession
        )

        self.oauthManager = oauth
        self.apiClient = client
        self.profileService = SpotifyProfileService(apiClient: client)
        self.playlistService = SpotifyPlaylistService(apiClient: client)
        self.libraryService = SpotifyLibraryService(apiClient: client)
        self.searchService = SpotifySearchService(apiClient: client)
        self.metadataService = SpotifyMetadataService(apiClient: client)
    }

    /// Custom initializer permitting dependency injection (e.g. for mock clients in unit tests).
    public init(
        oauthManager: SpotifyOAuthManager,
        apiClient: SpotifyAPIClientProtocol,
        tokenStorage: SecureTokenStorageProtocol
    ) {
        self.oauthManager = oauthManager
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage
        self.profileService = SpotifyProfileService(apiClient: apiClient)
        self.playlistService = SpotifyPlaylistService(apiClient: apiClient)
        self.libraryService = SpotifyLibraryService(apiClient: apiClient)
        self.searchService = SpotifySearchService(apiClient: apiClient)
        self.metadataService = SpotifyMetadataService(apiClient: apiClient)
    }

    // MARK: - SpotifyServiceProtocol

    public var isAuthenticated: Bool {
        return tokenStorage.getAccessToken() != nil
    }

    public func authenticate() async throws {
        // Generates the authorization URL; on iOS this is opened via ASWebAuthenticationSession
        _ = oauthManager.createAuthorizationURL()
    }

    public func disconnect() async throws {
        try await oauthManager.disconnect()
    }

    public func getUserPlaylists(limit: Int = 20, offset: Int = 0) async throws -> [SpotifyPlaylistMetadata] {
        let dtos = try await playlistService.getCurrentUserPlaylists(limit: limit, offset: offset)
        return dtos.map { SpotifyModelMapper.mapToPlaylistMetadata($0) }
    }

    public func getPlaylistTracks(playlistId: String, limit: Int = 100, offset: Int = 0) async throws -> [SpotifyTrackMetadata] {
        let items = try await playlistService.getPlaylistTracks(playlistId: playlistId, limit: limit, offset: offset)
        return items.compactMap { item in
            guard let trackDTO = item.track else { return nil }
            return SpotifyModelMapper.mapToTrackMetadata(trackDTO)
        }
    }

    public func searchCatalog(query: String, limit: Int = 20) async throws -> [SpotifyTrackMetadata] {
        let searchResponse = try await searchService.searchCatalog(query: query, types: ["track"], limit: limit)
        guard let trackPaging = searchResponse.tracks else { return [] }
        return trackPaging.items.map { SpotifyModelMapper.mapToTrackMetadata($0) }
    }

    public func getArtist(spotifyId: String) async throws -> Artist? {
        let artistDTO = try await metadataService.getArtist(id: spotifyId)
        return SpotifyModelMapper.mapToArtist(artistDTO)
    }

    public func getAlbum(spotifyId: String) async throws -> Album? {
        let albumDTO = try await metadataService.getAlbum(id: spotifyId)
        return SpotifyModelMapper.mapToAlbum(albumDTO)
    }

    public func getAuthorizationURL() -> URL? {
        return oauthManager.createAuthorizationURL()
    }

    public func handleRedirectURL(_ url: URL) async throws -> Bool {
        _ = try await oauthManager.handleRedirectURL(url)
        return true
    }
}
