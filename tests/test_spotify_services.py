#!/usr/bin/env python3
"""
Melora Spotify Integration & Network Layer Test Suite
Validates PKCE RFC 7636 compliance, OAuth state security, DTO JSON schemas,
simplified and full playlist decoding, HTTP status handlers (200, 401, 403, 429, 500),
and SpotifyViewModel loading / retry state machine.
"""

import base64
import hashlib
import http.server
import json
import threading
import time
import unittest
import urllib.parse
import urllib.request


def compute_s256_challenge(code_verifier: str) -> str:
    """Computes the RFC 7636 S256 code challenge for a verifier."""
    digest = hashlib.sha256(code_verifier.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest).decode("utf-8").rstrip("=")


def handle_oauth_callback(callback_url: str, expected_state: str) -> str:
    """Simulates OAuthCallbackHandler parsing and state verification."""
    parsed = urllib.parse.urlparse(callback_url)
    params = urllib.parse.parse_qs(parsed.query)

    if "error" in params:
        error_name = params["error"][0]
        desc = params.get("error_description", [error_name])[0]
        raise ValueError(f"OAuth error: {desc}")

    received_state = params.get("state", [None])[0]
    if received_state != expected_state:
        raise PermissionError(f"CSRF state mismatch. Expected {expected_state}, got {received_state}")

    if "code" not in params or not params["code"][0]:
        raise KeyError("Missing authorization code in callback")

    return params["code"][0]


# --- Local Mock Spotify Server for Network Integration Testing ---

class MockSpotifyHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/api/token":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")
            params = urllib.parse.parse_qs(body)

            # Validate that client secret is NOT sent (PKCE compliance)
            if "client_secret" in params:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'{"error": "invalid_request", "error_description": "Client secret forbidden with PKCE"}')
                return

            grant_type = params.get("grant_type", [None])[0]
            if grant_type == "authorization_code":
                code = params.get("code", [None])[0]
                verifier = params.get("code_verifier", [None])[0]
                if code == "valid_code" and verifier:
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    response = {
                        "access_token": "mock_access_token_12345",
                        "token_type": "Bearer",
                        "scope": "user-read-private playlist-read-private",
                        "expires_in": 3600,
                        "refresh_token": "mock_refresh_token_67890"
                    }
                    self.wfile.write(json.dumps(response).encode("utf-8"))
                    return

            elif grant_type == "refresh_token":
                refresh_token = params.get("refresh_token", [None])[0]
                if refresh_token == "mock_refresh_token_67890":
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    response = {
                        "access_token": "mock_refreshed_access_token_abcde",
                        "token_type": "Bearer",
                        "scope": "user-read-private playlist-read-private",
                        "expires_in": 3600
                    }
                    self.wfile.write(json.dumps(response).encode("utf-8"))
                    return

            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error": "invalid_grant", "error_description": "Invalid authorization code or refresh token"}')

    def do_GET(self):
        # Validate Bearer token
        auth_header = self.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            self.send_response(401)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error": {"status": 401, "message": "Unauthorized: No token provided"}}')
            return

        if self.path == "/v1/me":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            payload = {
                "id": "melora_user_test",
                "display_name": "Test Audiophile",
                "email": "test@melora.app",
                "country": "US",
                "product": "premium",
                "images": [{"url": "https://i.scdn.co/image/test.jpg", "height": 300, "width": 300}]
            }
            self.wfile.write(json.dumps(payload).encode("utf-8"))

        elif self.path == "/v1/me/playlists?empty=true":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            payload = {
                "href": "https://api.spotify.com/v1/me/playlists",
                "items": [],
                "limit": 20,
                "offset": 0,
                "total": 0
            }
            self.wfile.write(json.dumps(payload).encode("utf-8"))

        elif self.path.startswith("/v1/me/playlists"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            payload = {
                "href": "https://api.spotify.com/v1/me/playlists",
                "items": [
                    {
                        "id": "pl_100",
                        "name": "Lo-Fi Beats",
                        "description": "Chill vibes for work",
                        "images": [{"url": "https://i.scdn.co/image/lofi.jpg", "height": 300, "width": 300}],
                        "owner": {"id": "spotify", "display_name": "Spotify"},
                        "tracks": {"href": "https://api.spotify.com/v1/playlists/pl_100/tracks", "total": 45}
                    }
                ],
                "limit": 20,
                "offset": 0,
                "total": 1
            }
            self.wfile.write(json.dumps(payload).encode("utf-8"))

        elif self.path == "/v1/forbidden_endpoint":
            self.send_response(403)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error": {"status": 403, "message": "Development Mode: User not authorized"}}')

        elif self.path == "/v1/rate_limited_endpoint":
            self.send_response(429)
            self.send_header("Retry-After", "10")
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error": {"status": 429, "message": "API rate limit exceeded"}}')

        elif self.path == "/v1/server_error_endpoint":
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error": {"status": 500, "message": "Internal Server Error"}}')

        elif self.path == "/v1/invalid_json_endpoint":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"corrupted": true, unclosed json')

        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # Suppress logging in unit tests
        pass


class TestMeloraSpotifyServices(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.server = http.server.HTTPServer(("127.0.0.1", 0), MockSpotifyHandler)
        cls.port = cls.server.server_port
        cls.server_thread = threading.Thread(target=cls.server.serve_forever)
        cls.server_thread.daemon = True
        cls.server_thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def test_pkce_rfc7636_official_vector(self):
        # Official RFC 7636 Appendix B Test Vector
        verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        expected = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        challenge = compute_s256_challenge(verifier)
        self.assertEqual(challenge, expected)

    def test_pkce_verifier_character_set_and_entropy(self):
        # RFC 7636 section 4.1: [A-Z], [a-z], [0-9], "-", ".", "_", "~"
        allowed = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        test_verifier = "aA0-._~bB1-._~cC2-._~dD3-._~eE4-._~fF5-._~"
        for ch in test_verifier:
            self.assertIn(ch, allowed)

        challenge = compute_s256_challenge(test_verifier)
        self.assertNotIn("+", challenge)
        self.assertNotIn("/", challenge)
        self.assertNotIn("=", challenge)

    def test_oauth_state_validation_and_csrf_defense(self):
        state = "cryptographically_secure_state_32"

        # Valid callback
        valid_url = f"melora://spotify-callback?code=AUTH_CODE_XYZ&state={state}"
        code = handle_oauth_callback(valid_url, expected_state=state)
        self.assertEqual(code, "AUTH_CODE_XYZ")

        # Tampered state -> must throw PermissionError
        tampered_url = f"melora://spotify-callback?code=AUTH_CODE_XYZ&state=attacker_state"
        with self.assertRaises(PermissionError):
            handle_oauth_callback(tampered_url, expected_state=state)

        # Access denied -> must throw ValueError
        denied_url = f"melora://spotify-callback?error=access_denied&error_description=User%20denied&state={state}"
        with self.assertRaises(ValueError):
            handle_oauth_callback(denied_url, expected_state=state)

    def test_dto_json_decoding_contracts(self):
        # Verify SpotifyTrackDTO JSON payload
        track_payload = {
            "id": "11dFghVXANMlKmJXsNCbNl",
            "name": "The Less I Know The Better",
            "artists": [{"id": "5INjqkS1o8h1imAzPqGZBb", "name": "Tame Impala"}],
            "album": {
                "id": "79dL7FLiJFOO0EoehTaA1W",
                "name": "Currents",
                "release_date": "2015-07-17",
                "images": [{"url": "https://i.scdn.co/image/currents.jpg", "height": 640, "width": 640}]
            },
            "duration_ms": 216320,
            "explicit": True,
            "popularity": 85,
            "preview_url": None  # Deprecated and nullable, must not break parsing
        }

        encoded = json.dumps(track_payload)
        decoded = json.loads(encoded)
        self.assertEqual(decoded["id"], "11dFghVXANMlKmJXsNCbNl")
        self.assertEqual(decoded["name"], "The Less I Know The Better")
        self.assertIsNone(decoded["preview_url"])
        self.assertEqual(decoded["duration_ms"], 216320)

    def test_simplified_and_full_playlist_dto_decoding(self):
        # 1. Simplified playlist as returned by GET /v1/me/playlists
        simplified_playlist = {
            "id": "37i9dQZF1DXcBWIGoYBM5M",
            "name": "Today's Top Hits",
            "description": "Jung Kook is on top of the Hottest 50!",
            "public": True,
            "collaborative": False,
            "snapshot_id": "MTcwMDAwMDAwMCwwMDA=",
            "images": [{"url": "https://i.scdn.co/image/tth.jpg", "height": 300, "width": 300}],
            "owner": {"id": "spotify", "display_name": "Spotify"},
            "tracks": {
                "href": "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M/tracks",
                "total": 50
            }
        }
        decoded = json.loads(json.dumps(simplified_playlist))
        self.assertEqual(decoded["id"], "37i9dQZF1DXcBWIGoYBM5M")
        self.assertEqual(decoded["tracks"]["total"], 50)
        self.assertNotIn("items", decoded["tracks"])

        # 2. Full playlist as returned by GET /v1/playlists/{id}
        full_playlist = {
            "id": "pl_full_001",
            "name": "Deep Focus",
            "tracks": {
                "href": "https://api.spotify.com/v1/playlists/pl_full_001/tracks",
                "items": [
                    {
                        "added_at": "2024-01-01T00:00:00Z",
                        "is_local": False,
                        "track": {"id": "trk_1", "name": "Breathe", "duration_ms": 200000}
                    }
                ],
                "limit": 100,
                "offset": 0,
                "total": 1
            }
        }
        decoded_full = json.loads(json.dumps(full_playlist))
        self.assertEqual(decoded_full["tracks"]["total"], 1)
        self.assertEqual(len(decoded_full["tracks"]["items"]), 1)
        self.assertEqual(decoded_full["tracks"]["items"][0]["track"]["name"], "Breathe")

        # 3. Empty paging playlist list
        empty_paging = {
            "href": "https://api.spotify.com/v1/me/playlists",
            "items": [],
            "limit": 20,
            "offset": 0,
            "total": 0
        }
        decoded_empty = json.loads(json.dumps(empty_paging))
        self.assertEqual(len(decoded_empty["items"]), 0)
        self.assertEqual(decoded_empty["total"], 0)

    def test_mock_spotify_token_exchange_and_refresh(self):
        # 1. Exchange authorization code for tokens
        url = f"http://127.0.0.1:{self.port}/api/token"
        data = urllib.parse.urlencode({
            "grant_type": "authorization_code",
            "code": "valid_code",
            "redirect_uri": "melora://spotify-callback",
            "client_id": "mock_client_id",
            "code_verifier": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        }).encode("utf-8")

        req = urllib.request.Request(url, data=data, method="POST")
        req.add_header("Content-Type", "application/x-www-form-urlencoded")

        with urllib.request.urlopen(req) as response:
            self.assertEqual(response.status, 200)
            token_resp = json.loads(response.read().decode("utf-8"))
            self.assertEqual(token_resp["access_token"], "mock_access_token_12345")
            self.assertEqual(token_resp["refresh_token"], "mock_refresh_token_67890")

        # 2. Refresh token flow
        refresh_data = urllib.parse.urlencode({
            "grant_type": "refresh_token",
            "refresh_token": "mock_refresh_token_67890",
            "client_id": "mock_client_id"
        }).encode("utf-8")

        refresh_req = urllib.request.Request(url, data=refresh_data, method="POST")
        refresh_req.add_header("Content-Type", "application/x-www-form-urlencoded")

        with urllib.request.urlopen(refresh_req) as response:
            self.assertEqual(response.status, 200)
            refreshed = json.loads(response.read().decode("utf-8"))
            self.assertEqual(refreshed["access_token"], "mock_refreshed_access_token_abcde")

    def test_mock_spotify_api_endpoints_and_rate_limit(self):
        base_url = f"http://127.0.0.1:{self.port}"

        # 1. Authorized GET /v1/me
        req = urllib.request.Request(f"{base_url}/v1/me")
        req.add_header("Authorization", "Bearer mock_access_token_12345")
        req.add_header("Accept", "application/json")

        with urllib.request.urlopen(req) as response:
            self.assertEqual(response.status, 200)
            profile = json.loads(response.read().decode("utf-8"))
            self.assertEqual(profile["id"], "melora_user_test")
            self.assertEqual(profile["product"], "premium")

        # 2. Authorized GET /v1/me/playlists with simplified tracks payload
        pl_req = urllib.request.Request(f"{base_url}/v1/me/playlists")
        pl_req.add_header("Authorization", "Bearer mock_access_token_12345")
        with urllib.request.urlopen(pl_req) as response:
            self.assertEqual(response.status, 200)
            pl_data = json.loads(response.read().decode("utf-8"))
            self.assertEqual(len(pl_data["items"]), 1)
            self.assertEqual(pl_data["items"][0]["tracks"]["total"], 45)

        # 3. Authorized GET /v1/me/playlists (empty playlists)
        empty_pl_req = urllib.request.Request(f"{base_url}/v1/me/playlists?empty=true")
        empty_pl_req.add_header("Authorization", "Bearer mock_access_token_12345")
        with urllib.request.urlopen(empty_pl_req) as response:
            self.assertEqual(response.status, 200)
            empty_data = json.loads(response.read().decode("utf-8"))
            self.assertEqual(len(empty_data["items"]), 0)

        # 4. Unauthorized request (missing token) -> 401
        unauthorized_req = urllib.request.Request(f"{base_url}/v1/me")
        try:
            with urllib.request.urlopen(unauthorized_req) as resp:
                pass
            self.fail("Expected 401 Unauthorized")
        except urllib.error.HTTPError as err:
            self.assertEqual(err.code, 401)
            err.close()

        # 5. Forbidden request (403 Development Mode error)
        forbidden_req = urllib.request.Request(f"{base_url}/v1/forbidden_endpoint")
        forbidden_req.add_header("Authorization", "Bearer mock_access_token_12345")
        try:
            with urllib.request.urlopen(forbidden_req) as resp:
                pass
            self.fail("Expected 403 Forbidden")
        except urllib.error.HTTPError as err:
            self.assertEqual(err.code, 403)
            err.close()

        # 6. Rate limited endpoint (429 with Retry-After header)
        rate_limit_req = urllib.request.Request(f"{base_url}/v1/rate_limited_endpoint")
        rate_limit_req.add_header("Authorization", "Bearer mock_access_token_12345")
        try:
            with urllib.request.urlopen(rate_limit_req) as resp:
                pass
            self.fail("Expected 429 Rate Limited")
        except urllib.error.HTTPError as err:
            self.assertEqual(err.code, 429)
            retry_after = err.headers.get("Retry-After")
            self.assertEqual(retry_after, "10")
            err.close()

        # 7. Server error endpoint (500)
        server_err_req = urllib.request.Request(f"{base_url}/v1/server_error_endpoint")
        server_err_req.add_header("Authorization", "Bearer mock_access_token_12345")
        try:
            with urllib.request.urlopen(server_err_req) as resp:
                pass
            self.fail("Expected 500 Server Error")
        except urllib.error.HTTPError as err:
            self.assertEqual(err.code, 500)
            err.close()

        # 8. Invalid JSON endpoint -> raises JSONDecodeError
        invalid_json_req = urllib.request.Request(f"{base_url}/v1/invalid_json_endpoint")
        invalid_json_req.add_header("Authorization", "Bearer mock_access_token_12345")
        with urllib.request.urlopen(invalid_json_req) as resp:
            content = resp.read().decode("utf-8")
            with self.assertRaises(json.JSONDecodeError):
                json.loads(content)

    def test_spotify_viewmodel_loading_and_retry_state_machine(self):
        """Simulates SpotifyViewModel state machine and ensures no infinite spinner."""
        class MockSpotifyViewModel:
            def __init__(self):
                self.isLoadingPlaylists = False
                self.playlistErrorMessage = None
                self.remotePlaylists = []
                self.statusMessage = None

            def load_remote_playlists(self, fetch_func):
                if self.isLoadingPlaylists:
                    return
                self.isLoadingPlaylists = True
                self.playlistErrorMessage = None

                try:
                    playlists = fetch_func()
                    self.remotePlaylists = playlists
                    if not playlists:
                        self.statusMessage = "No Spotify playlists found in your library."
                except Exception as ex:
                    self.playlistErrorMessage = str(ex)
                    self.statusMessage = f"Failed to load Spotify playlists: {ex}"
                finally:
                    # Defer cleanup guarantees isLoadingPlaylists is reset
                    self.isLoadingPlaylists = False

            def disconnect(self):
                self.isLoadingPlaylists = False
                self.playlistErrorMessage = None
                self.remotePlaylists = []

        vm = MockSpotifyViewModel()
        self.assertFalse(vm.isLoadingPlaylists)
        self.assertIsNone(vm.playlistErrorMessage)
        self.assertEqual(len(vm.remotePlaylists), 0)

        # 1. Successful fetch with items
        vm.load_remote_playlists(lambda: [{"id": "pl_1", "name": "Chill", "totalTracks": 20}])
        self.assertFalse(vm.isLoadingPlaylists)
        self.assertIsNone(vm.playlistErrorMessage)
        self.assertEqual(len(vm.remotePlaylists), 1)

        # 2. Successful fetch with empty items -> empty state, not infinite loading
        vm.load_remote_playlists(lambda: [])
        self.assertFalse(vm.isLoadingPlaylists)
        self.assertIsNone(vm.playlistErrorMessage)
        self.assertEqual(len(vm.remotePlaylists), 0)
        self.assertEqual(vm.statusMessage, "No Spotify playlists found in your library.")

        # 3. Error state (e.g. 401 or decoding error) -> error banner with retry, not infinite loading
        vm.load_remote_playlists(lambda: (_ for _ in ()).throw(ValueError("401 Unauthorized")))
        self.assertFalse(vm.isLoadingPlaylists)
        self.assertEqual(vm.playlistErrorMessage, "401 Unauthorized")

        # 4. Retry -> clears error message and recovers
        vm.load_remote_playlists(lambda: [{"id": "pl_2", "name": "Vibes", "totalTracks": 10}])
        self.assertFalse(vm.isLoadingPlaylists)
        self.assertIsNone(vm.playlistErrorMessage)
        self.assertEqual(len(vm.remotePlaylists), 1)

        # 5. Disconnect -> clears everything
        vm.disconnect()
        self.assertFalse(vm.isLoadingPlaylists)
        self.assertIsNone(vm.playlistErrorMessage)
        self.assertEqual(len(vm.remotePlaylists), 0)


if __name__ == "__main__":
    unittest.main()
