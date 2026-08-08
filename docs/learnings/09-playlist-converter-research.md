# Playlist Converter & Cloud Sync — Research Findings

## Date: 2026-08-08

## Problem Statement
TuneVerse needs two backend-dependent features:
1. **Playlist conversion** — import playlists from Amazon Music (primary), Spotify (later) into TuneVerse by matching tracks against YouTube
2. **Cloud backup/sync** — persist playlists, favorites, and profile data so they survive app reinstalls and can sync across devices

## Research: Amazon Music API

**Official API exists but is closed beta.** Amazon has a Web API (V1.0) with full playlist CRUD endpoints and library access. Access requires approval from an Amazon Business Development representative — not publicly available.

**Login with Amazon (LWA) OAuth** has music scopes: `music::library` (read/write) and `music::library:read` (read-only). These scopes only activate after your Security Profile is explicitly enabled by Amazon's team.

**How TuneMyMusic/Soundiiz/FreeYourMusic do it:** They are approved partners using the official API via OAuth. None of them scrape.

**Unofficial/reverse-engineered GitHub repos:**
| Repo | Language | Approach | Notes |
|------|----------|----------|-------|
| `Jaffa/amazon-music` | Python | Browser session cookies | Apache 2.0, most reliable |
| `AmineSoukara/amazon-music` | Python/FastAPI | Cookie-based, on PyPI | Requires Premium account |
| `notdeltaxd/Amazon-Music-API` | TypeScript/Bun | Metadata-only REST | Lightweight |
| `projecteurlumiere/save_amazon_music_playlist` | JS userscript | Browser extension export | Manual, one-time |

**Conclusion:** Without closed-beta approval, cookie-based session extraction via `Jaffa/amazon-music` is the most viable path.

## Research: Spotify Free Tier

**Critical change (February 2026):** Spotify tightened developer access:
- App owner must hold **active Premium subscription** for Development Mode
- Only **5 test users** per app (down from 25)
- Playlist track listings only returned for playlists the **user owns or collaborates on**
- Search capped at **10 results** per request
- Many endpoints removed (Create Playlist, Get Artist's Top Tracks, batch endpoints)
- Extended Quota Mode requires registered business with 250k+ MAU

**Android SDK vs Web API distinction:**
- **Android SDK** — thin layer controlling the installed Spotify app (play/pause/skip, current track). NOT for data access.
- **Web API** — full REST API for catalog search, playlist CRUD, library management. This is what reads playlists.
- The Android SDK's auth module can produce tokens for the Web API, so they're often used together.

**Conclusion:** Spotify integration requires Premium on the developer account. Functional for personal use with the user's own credentials but not scalable to other users without Extended Quota Mode.

## Research: Backend Options

### Evaluated: Google Drive, Appwrite, Supabase, MongoDB Atlas

**Google Drive** — Dismissed. Overkill for JSON backup. Requires Drive API scoping, complex OAuth, and user confusion about storage location.

**MongoDB Atlas** — Not recommended. Atlas App Services (BaaS layer with auth, sync, auto-generated APIs) was shut down September 2025. Now just a raw database requiring a custom API layer.

**Appwrite vs Supabase comparison:**

| | Appwrite | Supabase |
|---|---|---|
| DB storage (free) | **2 GB** | 500 MB |
| File storage (free) | **2 GB** | 1 GB |
| MAU cap (free) | **75,000** | 50,000 |
| Flutter SDK | Official, 130 pub pts, 580 likes | Official, 160 pub pts, 976 likes |
| Auth providers | **40+** OAuth, MFA, anonymous | 19 OAuth, passkeys beta, anonymous |
| Self-hosting | **Single Docker command** | 11+ containers |
| Realtime | WebSocket subscriptions | WebSocket + Broadcast + Presence |
| Functions | Python/Node/Go/Dart | Edge Functions (Deno/TypeScript) |

**Decision: Appwrite Cloud (free tier)** — more generous storage, simpler self-hosting path if needed later, sufficient Flutter SDK, and serverless functions support Python (needed for Amazon Music library).

## Research: Open-Source Playlist Converter Tools

**Downloaders (Spotify metadata + YouTube audio):**
- **spotDL** (~25.7k stars) — Python, uses Spotify API for metadata + yt-dlp for audio. `pip install spotdl`
- **SpotiFlyer** (~11.2k stars) — Kotlin Multiplatform. Unmaintained since Nov 2023

**Playlist transfer (no downloading):**
- **spotify_to_ytmusic** (~1.5k stars) — Python, Spotify→YTMusic via official APIs + ytmusicapi
- **SyncDisBoi** (~130 stars) — Rust, bidirectional Spotify/YTMusic/Tidal. Uses ISRC matching + Levenshtein fallback
- **ultrasonics** (~275 stars) — Python, plugin-based universal sync engine

**Track matching approaches used across tools:**
1. **ISRC matching** — most accurate, uses International Standard Recording Code (not always available)
2. **Fuzzy string matching** — title + artist comparison with Levenshtein distance
3. **Duration similarity** — secondary signal to disambiguate fuzzy matches
4. **Combined score** — weighted combination of title match + artist match + duration proximity

**No tool has official Amazon Music support** — confirming the closed-beta API situation.
