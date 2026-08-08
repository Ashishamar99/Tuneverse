# Appwrite Backend Architecture — Playlist Converter & Cloud Sync

## Date: 2026-08-08

## Decision
Use **Appwrite Cloud (free tier)** as a unified backend for both playlist conversion and cloud backup/sync. No separate server or VPS needed — everything runs as Appwrite managed services and serverless functions.

## Why Appwrite Over Alternatives
- **Google Drive** — dismissed as overkill for JSON backup; complex OAuth scoping
- **MongoDB Atlas** — App Services (BaaS) shut down Sept 2025; now just a raw database
- **Supabase** — viable but Appwrite has 4x storage (2GB vs 500MB), 50% more MAU (75K vs 50K), and simpler self-hosting if needed later
- **Firebase** — vendor lock-in, harder to self-host, cost scales unpredictably

## Appwrite Cloud Free Tier Limits
| Resource | Limit |
|---|---|
| Database storage | 2 GB |
| File storage | 2 GB |
| Monthly active users | 75,000 |
| Function executions | 750K/month |
| Bandwidth | 300 GB/month |
| Realtime connections | Concurrent, WebSocket |

## Architecture

### Appwrite Resources

**Auth:** Google OAuth provider (identity for both features)

**Database: `tuneverse`**

Collection: `backups`
```json
{
  "$id": "auto",
  "userId": "google-uid",
  "profiles": [{"name": "...", "emoji": "...", "accent": 4280391411}],
  "playlists": [{"name": "...", "trackSourceIds": ["yt:dQw4w9WgXcQ", ...]}],
  "favorites": {"profileId": ["sourceId1", "sourceId2"]},
  "settings": {"lastActiveProfileId": "1"},
  "updatedAt": "2026-08-08T..."
}
```

Collection: `import_jobs`
```json
{
  "$id": "auto",
  "userId": "google-uid",
  "source": "amazon",
  "status": "processing|completed|failed",
  "playlists": [
    {
      "name": "My Amazon Playlist",
      "totalTracks": 42,
      "matched": 38,
      "notFound": 4,
      "tracks": [
        {
          "originalTitle": "Song Name",
          "originalArtist": "Artist",
          "matchedSourceId": "yt:abc123",
          "matchConfidence": "exact|fuzzy|not_found",
          "matchedTitle": "Song Name (Official Audio)"
        }
      ]
    }
  ],
  "createdAt": "2026-08-08T...",
  "expiresAt": "2026-08-15T..."  // 7 days TTL
}
```

Collection: `import_progress` (for realtime updates during conversion)
```json
{
  "$id": "job_{jobId}",
  "userId": "google-uid",
  "jobId": "import_jobs.$id",
  "currentPlaylist": "My Amazon Playlist",
  "processedTracks": 24,
  "totalTracks": 42,
  "lastMatchedTrack": "Song Name → yt:abc123 (exact)",
  "updatedAt": "2026-08-08T..."
}
```

### Appwrite Functions

**`convert-amazon`** (Python runtime)
- Trigger: HTTP endpoint
- Input: Amazon Music session cookies + optional playlist filter
- Process: Uses `Jaffa/amazon-music` library to fetch playlists
- Output: Creates `import_jobs` document, updates `import_progress` in realtime
- YouTube matching done client-side (app already has youtube_explode_dart)

**`convert-spotify`** (Python runtime, future)
- Trigger: HTTP endpoint
- Input: Spotify OAuth token
- Process: Spotify Web API to fetch playlists
- Output: Same import_jobs format

**`backup-cleanup`** (scheduled, daily)
- Trigger: Appwrite CRON schedule
- Process: Delete `import_jobs` and `import_progress` docs where `expiresAt < now()`
- Keeps the database clean

### Data Flow

**Backup flow:**
```
App detects playlist/favorite change
  → Serialize current Isar state to JSON
  → Appwrite SDK: update document in `backups` collection
  → (Debounced: max once per 30 seconds)

On fresh install + Google Sign-In:
  → Appwrite SDK: query `backups` for userId
  → If found: deserialize JSON → populate Isar
  → If not found: clean start
```

**Playlist conversion flow (Amazon Music):**
```
User taps "Import from Amazon Music"
  → WebView: amazon.com/music login
  → Capture session cookies after successful login
  → POST to Appwrite Function `convert-amazon` with cookies
  → Function creates import_job (status: "processing")
  → Function fetches playlists from Amazon Music API
  → Function writes track metadata to import_job document
  → App subscribes to realtime updates on import_progress
  → App shows live progress: "Fetching playlist 2/5... 24/42 tracks"
  → Function completes, sets status: "completed"
  → App receives final track list
  → App matches each track against YouTube (youtube_explode_dart)
  → App shows match results with confidence indicators
  → User reviews and confirms → creates TuneVerse playlists
  → import_job auto-expires after 7 days
```

**Match confidence display:**
- Exact: title + artist exact match → green checkmark
- Fuzzy: title similar, artist matches → yellow tilde
- Not found: no reasonable match → red X, user can manually search

## Hosting
Everything runs on Appwrite Cloud. No VPS, no Docker, no server management.

| Component | Hosted by |
|---|---|
| Auth (Google OAuth) | Appwrite Cloud |
| Database (backups, jobs, progress) | Appwrite Cloud |
| Functions (convert-amazon, cleanup) | Appwrite Cloud (serverless) |
| Realtime (progress WebSocket) | Appwrite Cloud |

## Security
- Amazon session cookies: transmitted to Appwrite Function over HTTPS, never stored in database, used only during function execution, discarded after
- Google OAuth tokens: managed by Appwrite, app never sees raw tokens
- Backup data: scoped by userId, Appwrite document-level permissions
- No secrets in app code — Appwrite project ID and endpoint are public (auth required for all operations)

## Future Extensions
- Spotify conversion (requires Premium on developer account)
- Apple Music conversion (MusicKit API)
- YouTube Music import (ytmusicapi)
- Multi-device realtime sync (Appwrite realtime subscriptions on backup changes)
- Self-hosted Appwrite migration (single Docker command, same SDK)
