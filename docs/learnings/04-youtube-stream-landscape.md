# YouTube Stream Extraction Landscape (2026)

## Current State
Open-source YouTube audio apps (NewPipe, BlackHole, ViMusic, InnerTune) all face
the same cat-and-mouse cycle with YouTube's anti-extraction measures.

## Key Developments
- **PO Token gate**: YouTube requires Proof of Origin tokens for clients that
  declare `androidSdkVersion`. Workaround: use `androidSdkless` client.
- **SABR protocol**: YouTube is migrating from plain HTTPS stream URLs to the
  Streaming ABR (SABR) protocol. This will eventually break all current
  extraction methods including `androidSdkless`.
- **Client rotation**: yt-dlp and youtube_explode_dart maintain multiple API
  clients (`ios`, `androidVr`, `safari`, `tv`, `mediaConnect`) and rotate when
  one stops working.

## Stream URL Lifetime
- YouTube stream URLs expire (typically 6 hours)
- TuneVerse caches for 5 hours; could reduce if expiry issues appear
- Caching too aggressively leads to stale URL playback failures

## Options for Resilience
1. **youtube_explode_dart updates**: Keep the dependency current; the maintainer
   tracks yt-dlp's client changes
2. **YouTube Data API v3 with OAuth**: Authenticated, rate-limited, but no direct
   audio stream access (only metadata + embeddable player)
3. **Fallback clients**: Try multiple `YoutubeApiClient` variants if one fails
4. **Server-side proxy**: Run yt-dlp on a server; more reliable but adds infra
