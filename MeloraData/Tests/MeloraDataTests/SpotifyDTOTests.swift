import Foundation
import Testing
@testable import MeloraCore
@testable import MeloraData

@Suite("Spotify DTO & Mapping Tests")
struct SpotifyDTOTests {

    @Test("Decode SpotifyTokenResponse")
    func testTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "BQB_sample_access_token_12345",
            "token_type": "Bearer",
            "scope": "user-read-private playlist-read-private",
            "expires_in": 3600,
            "refresh_token": "AQD_sample_refresh_token_67890"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SpotifyTokenResponse.self, from: json)
        #expect(response.accessToken == "BQB_sample_access_token_12345")
        #expect(response.tokenType == "Bearer")
        #expect(response.expiresIn == 3600)
        #expect(response.refreshToken == "AQD_sample_refresh_token_67890")
    }

    @Test("Decode SpotifyUserProfile and check Premium")
    func testUserProfileDecoding() throws {
        let json = """
        {
            "id": "melora_user_1",
            "display_name": "Melora Audiophile",
            "email": "user@example.com",
            "country": "US",
            "product": "premium",
            "images": [
                {
                    "url": "https://i.scdn.co/image/profile_pic.jpg",
                    "height": 300,
                    "width": 300
                }
            ],
            "uri": "spotify:user:melora_user_1"
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder().decode(SpotifyUserProfile.self, from: json)
        #expect(profile.id == "melora_user_1")
        #expect(profile.displayName == "Melora Audiophile")
        #expect(profile.isPremium == true)
        #expect(profile.avatarUrl == "https://i.scdn.co/image/profile_pic.jpg")
    }

    @Test("Decode SpotifyTrackDTO and map to Domain Metadata")
    func testTrackDTOMapping() throws {
        let json = """
        {
            "id": "11dFghVXANMlKmJXsNCbNl",
            "name": "The Less I Know The Better",
            "artists": [
                {
                    "id": "5INjqkS1o8h1imAzPqGZBb",
                    "name": "Tame Impala"
                }
            ],
            "album": {
                "id": "79dL7FLiJFOO0EoehTaA1W",
                "name": "Currents",
                "release_date": "2015-07-17",
                "images": [
                    {
                        "url": "https://i.scdn.co/image/currents.jpg",
                        "height": 640,
                        "width": 640
                    }
                ]
            },
            "duration_ms": 216320,
            "explicit": true,
            "popularity": 85,
            "disc_number": 1,
            "track_number": 7,
            "uri": "spotify:track:11dFghVXANMlKmJXsNCbNl",
            "is_playable": true
        }
        """.data(using: .utf8)!

        let trackDTO = try JSONDecoder().decode(SpotifyTrackDTO.self, from: json)
        #expect(trackDTO.id == "11dFghVXANMlKmJXsNCbNl")
        #expect(trackDTO.name == "The Less I Know The Better")
        #expect(trackDTO.primaryArtistName == "Tame Impala")
        #expect(trackDTO.artworkUrl == "https://i.scdn.co/image/currents.jpg")

        // Map to MeloraCore domain metadata
        let domainMetadata = SpotifyModelMapper.mapToTrackMetadata(trackDTO)
        #expect(domainMetadata.id == trackDTO.id)
        #expect(domainMetadata.title == trackDTO.name)
        #expect(domainMetadata.artistName == "Tame Impala")
        #expect(domainMetadata.albumTitle == "Currents")
        #expect(domainMetadata.isExplicit == true)
    }

    @Test("Decode SpotifyPlaylistDTO and map to Domain Metadata")
    func testPlaylistDTOMapping() throws {
        let json = """
        {
            "id": "37i9dQZF1DXcBWIGoYBM5M",
            "name": "Today's Top Hits",
            "description": "Jung Kook is on top of the Hottest 50!",
            "public": true,
            "collaborative": false,
            "snapshot_id": "MTcwMDAwMDAwMCwwMDA=",
            "images": [
                {
                    "url": "https://i.scdn.co/image/tth.jpg",
                    "height": 300,
                    "width": 300
                }
            ],
            "owner": {
                "id": "spotify",
                "display_name": "Spotify"
            },
            "tracks": {
                "href": "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M/tracks",
                "items": [],
                "limit": 100,
                "offset": 0,
                "total": 50
            }
        }
        """.data(using: .utf8)!

        let playlistDTO = try JSONDecoder().decode(SpotifyPlaylistDTO.self, from: json)
        #expect(playlistDTO.id == "37i9dQZF1DXcBWIGoYBM5M")
        #expect(playlistDTO.name == "Today's Top Hits")
        #expect(playlistDTO.totalTracks == 50)
        #expect(playlistDTO.owner?.displayName == "Spotify")

        let domainPlaylist = SpotifyModelMapper.mapToPlaylistMetadata(playlistDTO)
        #expect(domainPlaylist.id == playlistDTO.id)
        #expect(domainPlaylist.name == "Today's Top Hits")
        #expect(domainPlaylist.totalTracks == 50)
        #expect(domainPlaylist.ownerName == "Spotify")
    }
}
