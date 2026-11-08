# Melora - Spotify Web API Integration & Security Guide

---

## 1. Overview & Compliance Principles

Melora integrates with the **Spotify Web API** exclusively to provide metadata enrichment, playlist importing, saved track browsing, and music discovery. 

Melora strictly complies with the **Spotify Developer Terms of Service** and **Developer Policy**:
1. **OAuth 2.0 PKCE Only:** Uses Proof Key for Code Exchange (RFC 7636). Client secrets are **never** embedded or distributed within the iOS client app.
2. **Local Audio Exclusivity:** Melora plays user-owned local audio files (MP3, AAC, FLAC, ALAC, WAV). Melora **never** downloads, rips, captures, or extracts audio streams from Spotify.
3. **No Deprecated Preview Dependency:** Melora does not depend on Spotify's `preview_url` (which is deprecated and nullable) for music playback.
4. **No AI/ML Ingestion:** Per Spotify Developer Policy, Spotify metadata and content are **never** used to train artificial intelligence or machine-learning models.
5. **No Token Leaks:** Access and refresh tokens are treated as sensitive credentials and stored strictly in the **iOS Keychain**. Tokens are never logged to console or remote analytics.

---

## 2. Spotify Developer Dashboard Setup

To configure Melora with the Spotify Web API:

1. Log into the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
2. Click **Create an App**.
3. Fill in the app registration details:
   - **App name:** `Melora`
   - **App description:** `Native iOS music player for local libraries with Spotify playlist and metadata sync.`
   - **Redirect URIs:** Add `melora://spotify-callback` (for custom URL scheme) and your Universal Link if applicable.
   - **Which APIs or SDKs are you planning to use?** Select **Web API**.
4. Accept the Spotify Developer Terms of Service and click **Save**.
5. Copy the **Client ID** (do NOT copy or generate a Client Secret). Set this Client ID in Melora's app configuration.

---

## 3. Spotify Development Mode & Limitations

Newly created Spotify applications operate in **Development Mode** (Quota Mode) with the following platform constraints:

| Constraint | Limit in Development Mode | Production (Extended Quota) Mode |
| :--- | :--- | :--- |
| **Authorized Users** | Maximum **25 users** (must be manually added by Spotify account email in Dashboard under "User Management"). | Unlimited users worldwide. |
| **Rate Limits** | Conservative rolling rate limits across endpoints. Exceeding triggers HTTP `429 Too Many Requests`. | Higher custom quota limits. |
| **Commercial Use** | Non-commercial testing and personal use only. | Commercial use permitted with approval. |
| **Endpoint Availability** | Standard catalog endpoints (Browse, Search, Playlists, Tracks, Artists, Albums) are available for authorized users. | Full access to permitted endpoints. |

> [!IMPORTANT]
> In Development Mode, any Spotify account not explicitly registered in the Dashboard's **User Management** tab will receive an **HTTP 403 Forbidden** error during authorization or API access.

---

## 4. OAuth 2.0 PKCE Flow Architecture

Melora implements RFC 7636 Proof Key for Code Exchange using SHA-256 (`S256`):

```
+----------------------------------------------------------------------------------------+
|                                     MELORA CLIENT                                      |
+----------------------------------------------------------------------------------------+
    | 1. Generate 64-char high-entropy Code Verifier
    | 2. Compute S256 Code Challenge = Base64URL(SHA256(Verifier))
    | 3. Generate 32-char CSRF State
    v
[ Launch ASWebAuthenticationSession ]
    |
    | https://accounts.spotify.com/authorize?
    |   response_type=code
    |   &client_id=<CLIENT_ID>
    |   &scope=user-read-private%20playlist-read-private%20user-library-read
    |   &redirect_uri=melora://spotify-callback
    |   &state=<STATE>
    |   &code_challenge=<CHALLENGE>
    |   &code_challenge_method=S256
    v
+----------------------------------------------------------------------------------------+
|                                 SPOTIFY ACCOUNTS SERVICE                               |
+----------------------------------------------------------------------------------------+
    | User logs in and approves requested scopes
    v
[ Redirect to melora://spotify-callback?code=<AUTH_CODE>&state=<STATE> ]
    |
    v
+----------------------------------------------------------------------------------------+
|                               OAuthCallbackHandler                                     |
+----------------------------------------------------------------------------------------+
    | 1. Validates received state == expected state (CSRF mitigation)
    | 2. Extracts authorization code
    v
+----------------------------------------------------------------------------------------+
|                                   TokenManager                                         |
+----------------------------------------------------------------------------------------+
    | POST https://accounts.spotify.com/api/token
    | Body:
    |   grant_type=authorization_code
    |   &code=<AUTH_CODE>
    |   &redirect_uri=melora://spotify-callback
    |   &client_id=<CLIENT_ID>
    |   &code_verifier=<CODE_VERIFIER>
    v
[ Receive SpotifyTokenResponse ]
    | { access_token, refresh_token, expires_in: 3600 }
    v
[ Store in Keychain via KeychainTokenStorage ]
```

---

## 5. Scope Specifications

Melora requests only the minimal read scopes necessary for metadata discovery and playlist syncing:

| Scope | Purpose in Melora |
| :--- | :--- |
| `user-read-private` | Display user's profile name and country market in Settings. |
| `user-read-email` | Display user account details in Spotify Account settings. |
| `playlist-read-private` | Retrieve user's private playlists for local library matching. |
| `playlist-read-collaborative` | Retrieve collaborative playlists for local library matching. |
| `user-library-read` | Ingest saved tracks ("Liked Songs") for local matching. |

---

## 6. Token Lifecycle & Expiration Management

1. **Storage:**
   - Saved via `KeychainTokenStorage` with `kSecAttrAccessibleAfterFirstUnlock`.
   - Never stored in unencrypted `UserDefaults` or plaintext files.
2. **Proactive Refresh:**
   - Tokens are checked via `isTokenExpired(bufferSeconds: 60)`.
   - If an access token expires within 60 seconds, `TokenManager` refreshes it before dispatching the network request.
3. **Thundering Herd Mitigation:**
   - Managed via an internal Swift actor (`TokenManager`) so concurrent API calls share the same ongoing refresh task.
4. **Automatic 401 Recovery:**
   - `SpotifyAPIClient` catches HTTP 401, issues a token refresh, and automatically retries the failed request once.

---

## 7. Rate Limiting (HTTP 429) & Throttling

Spotify enforces per-client rate limits. If exceeded, Spotify returns:
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 12
Content-Type: application/json

{
  "error": {
    "status": 429,
    "message": "API rate limit exceeded"
  }
}
```

Melora's `SpotifyRateLimiter` automatically:
1. Inspects every response for status 429.
2. Extracts the `Retry-After` header value in seconds.
3. Sets an internal cooldown lock.
4. Awaits the cooldown interval asynchronously before releasing subsequent requests.

---

## 8. Mapping Spotify DTOs to Melora Domain Entities

| Spotify DTO (`MeloraData`) | Melora Domain Entity (`MeloraCore`) | Purpose |
| :--- | :--- | :--- |
| `SpotifyPlaylistDTO` | `SpotifyPlaylistMetadata` | Displaying imported playlists and track counts. |
| `SpotifyTrackDTO` | `SpotifyTrackMetadata` | Matching online tracks against local audio library files. |
| `SpotifyArtistDTO` | `Artist` | Enriching local artists with artwork URLs and Spotify IDs. |
| `SpotifyAlbumDTO` | `Album` | Enriching local albums with high-res cover art and release years. |
