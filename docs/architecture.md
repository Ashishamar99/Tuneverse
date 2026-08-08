# TuneVerse — Architecture Deep Dive

## Overview

TuneVerse follows Clean Architecture with three layers: **Presentation**, **Domain**, and **Data/Source**. The key design principle is that every feature — search, link resolution, downloads, playback — talks to a unified `TrackSource` interface. Swapping or adding sources never touches the playback engine or the UI.

---

## Layer Breakdown

### 1. Presentation Layer

- **Framework:** Flutter widgets + Riverpod providers/notifiers
- **Navigation:** Go Router (handles deep links from the universal link handler)
- **Screens:** Home, Search, Player (full-screen), Library, Profiles, Settings
- **Shared widgets:** MiniPlayer (persistent above bottom nav), AlbumArtHero, WaveformVisualiser

Riverpod is used over BLoC because it composes better for async streams (audio state is a stream, not a series of events) and integrates cleanly with Go Router's redirect logic for profile gating.

### 2. Domain Layer

Use cases are the sole entry point from the presentation layer into business logic.

| Use Case | Responsibility |
|---|---|
| `PlaybackUseCase` | Play, pause, seek, skip, loop mode, shuffle, queue management |
| `SearchUseCase` | Unified search across local Isar DB + YouTube |
| `ResolveUseCase` | Parse an external URL → resolve to a playable `TrackEntity` |
| `PlaylistUseCase` | Create/edit/delete playlists, add/remove tracks |
| `DownloadUseCase` | Download a track, track progress, manage offline files |
| `ProfileUseCase` | Switch active profile, create/delete profiles |

### 3. Source Layer

All audio sources implement `TrackSource`:

```dart
abstract class TrackSource {
  Future<TrackEntity> resolve(String query);
  Future<Uri> getStreamUri(TrackEntity track);
  Future<List<TrackEntity>> search(String query);
}
```

| Source | Implementation |
|---|---|
| `YouTubeSource` | `youtube_explode_dart` — search, stream URL extraction, quality selection |
| `LocalFileSource` | `on_audio_query` — Android MediaStore scan, ID3 tag reading |
| `ResolvedSource` | Wraps `YouTubeSource` after metadata fetch from Spotify/Amazon |

### 4. Platform Layer

| Integration | Package / Approach |
|---|---|
| Background playback + lock screen | `audio_service` |
| Android Auto | `MediaBrowserServiceCompat` via `audio_service`, `automotive_app_desc.xml` |
| Audio focus (calls, other apps) | `audio_service` session management |
| Bluetooth (headphone disconnect) | `AUDIO_BECOMING_NOISY` broadcast receiver via platform channel |
| Chromecast | `cast` Flutter package + Google Cast SDK |

### 5. Data Layer

**Database:** Isar (embedded, Flutter-native, extremely fast)

#### Schema

```dart
@collection
class TrackEntity {
  Id id = Isar.autoIncrement;
  late String title;
  late String artist;
  String? album;
  int? durationMs;
  String? artworkUrl;
  @enumerated
  late SourceType sourceType;   // youtube | local | cached
  late String sourceId;         // YouTube video ID or file path
  String? localPath;            // set when downloaded
  DateTime? downloadedAt;
  int playCount = 0;
}

@collection
class PlaylistEntity {
  Id id = Isar.autoIncrement;
  late String profileId;
  late String name;
  String? description;
  List<int> trackIds = [];
  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class ProfileEntity {
  Id id = Isar.autoIncrement;
  late String name;
  late String avatarEmoji;
  late int accentColorValue;
  late DateTime createdAt;
  bool isActive = false;
}

@collection
class QueueEntity {
  Id id = Isar.autoIncrement;
  late String profileId;
  List<int> trackIds = [];
  int currentIndex = 0;
  @enumerated
  LoopMode loopMode = LoopMode.off;
  bool shuffled = false;
}
```

---

## Universal Link Resolver

The most architecturally interesting subsystem. Flow:

```
Incoming URL (e.g. https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh)
  │
  ▼
LinkParser.identify(url) → { platform: spotify, type: track, id: "4iV5W9uYEdYUVa79Axb7Rh" }
  │
  ▼
MetadataFetcher:
  ├── SpotifyFetcher   → GET /tracks/{id} (Spotify Web API) → { title, artist, duration }
  ├── AmazonFetcher    → parse share page HTML → { title, artist }
  └── YouTubeFetcher   → youtube_explode_dart → direct video entity
  │
  ▼
YouTubeSearch.findBestMatch(title, artist, durationMs)
  → score candidates by: title similarity + artist match + duration proximity
  → return best VideoId
  │
  ▼
TrackEntity (resolved, ready for AudioEngine)
```

**Spotify credentials:** User provides Client ID + Client Secret in app Settings. Stored in Android Keystore via `flutter_secure_storage`. Never in source code.

**Amazon Music:** No public API. We request the share URL, parse the Open Graph `og:title` and `og:description` meta tags for track + artist, then search YouTube.

---

## Audio Engine

```
AudioController (Riverpod provider)
  │
  ├── just_audio AudioPlayer
  │     ├── ConcatenatingAudioSource (queue)
  │     ├── Stream<PlayerState>
  │     └── Stream<Duration> (position)
  │
  ├── audio_service AudioHandler
  │     ├── MediaItem (lock screen / notification)
  │     ├── Android Auto MediaBrowserService
  │     └── MediaSession (system media controls)
  │
  └── AudioVisualiserController
        ├── audio_visualizer FFT stream
        └── SineWavePainter (CustomPainter, 60fps)
```

---

## Fluid Sine Wave Visualiser

Three layered sine waves rendered via `CustomPainter`:

```
Wave 1: base frequency f,     opacity 0.9, accent colour
Wave 2: frequency f * 1.3,    opacity 0.5, accent colour lightened
Wave 3: frequency f * 0.7,    opacity 0.3, accent colour darkened
```

Amplitude is driven by the FFT output from `audio_visualizer` (supports HTTP audio streams). Phase offset advances with playback position. The result is a breathing, reactive waveform that tracks the music.

For YouTube streams: `audio_visualizer` accepts the stream URL directly. For local files: it reads from the file URI.

---

## UI Design System

| Token | Value |
|---|---|
| Background | `#080808` |
| Surface | `#141414` |
| Surface elevated | `#1E1E1E` |
| Accent | Dynamic from `palette_generator` (album art) |
| On-accent | White or near-black, whichever has ≥4.5:1 contrast |
| Corner radius | 16dp standard, 24dp cards, 32dp player art |
| Typography | Plus Jakarta Sans (variable weight) |
| Motion | Spring physics for controls, `Curves.easeOutCubic` for transitions |

### Player Screen Layout

```
┌─────────────────────────────────┐
│  ↓ swipe to dismiss             │
│                                 │
│       ┌───────────────┐        │
│       │               │        │
│       │  album art    │        │
│       │  (ambient     │        │
│       │   glow blur)  │        │
│       └───────────────┘        │
│                                 │
│  ≈≈≈≈≈≈≈ sine waves ≈≈≈≈≈≈≈  │
│                                 │
│  Song Title              ···   │
│  Artist Name             ♡     │
│                                 │
│  ━━━━━━━━●━━━━━━━━━━━━━━      │
│  1:24                  4:02    │
│                                 │
│     ⇄     ⏮   ▶▶   ⏭   ↺   │
│                                 │
│  🔊 ──────●──────── Cast 📡   │
└─────────────────────────────────┘
```

---

## Backend — Appwrite Cloud

TuneVerse uses Appwrite Cloud (free tier) as a lightweight backend for two features:

1. **Cloud Backup/Sync** — playlists, favorites, and profile data persisted to Appwrite Database, auto-restored on fresh install with Google Sign-In
2. **Playlist Converter** — import playlists from Amazon Music (and later Spotify) via Appwrite Functions

See `docs/learnings/10-appwrite-backend-architecture.md` for the full schema, data flows, and hosting details.

```
┌────────────────────────────────────────────────┐
│              Appwrite Cloud                    │
│                                                │
│  Auth ── Google Sign-In                        │
│  DB   ── backups, import_jobs, import_progress │
│  Fn   ── convert-amazon, backup-cleanup        │
│  RT   ── WebSocket progress updates            │
└────────────────────────────────────────────────┘
```

Backend code lives in `backend/appwrite/` in this repo.

---

## Secrets Management

No secrets in source code. Ever.

```
lib/config/secrets.dart          ← gitignored, user creates this
lib/config/secrets.dart.example  ← committed, template only
```

`secrets.dart.example`:
```dart
// Copy this file to secrets.dart and fill in your values.
// secrets.dart is gitignored — never commit it.
class AppSecrets {
  static const spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
}
```

At runtime, Spotify tokens are fetched server-side (Client Credentials flow) and cached in memory. The client secret never leaves the device.

---

## Android Auto

Android Auto requires:
1. `automotive_app_desc.xml` declaring the app as a media app
2. `MediaBrowserServiceCompat` implementation (provided by `audio_service`)
3. A content hierarchy for browsable content:
   ```
   Root
   ├── Playlists
   │   ├── Playlist 1
   │   └── Playlist 2
   ├── Recently Played
   └── Library (all tracks)
   ```
4. Media action handling: play, pause, skip, seek, shuffle toggle

---

## Directory Structure

```
lib/
├── core/
│   ├── di/                  # Riverpod providers registration
│   ├── router/              # Go Router config + deep link handler
│   ├── theme/               # Design tokens, ThemeData, dynamic colour
│   └── constants/           # API endpoints, timeouts, asset paths
│
├── data/
│   ├── models/              # Isar @collection classes
│   ├── repositories/        # Implementations of domain interfaces
│   ├── sources/
│   │   ├── youtube/         # YouTubeSource implementation
│   │   ├── local/           # LocalFileSource + on_audio_query
│   │   └── resolver/        # UniversalLinkResolver
│   └── platform/
│       ├── audio_handler.dart   # audio_service AudioHandler
│       ├── auto_handler.dart    # Android Auto
│       └── cast_manager.dart   # Chromecast
│
├── domain/
│   ├── entities/            # TrackEntity, PlaylistEntity, etc.
│   ├── interfaces/          # TrackSource, Repository interfaces
│   └── usecases/            # One file per use case
│
├── presentation/
│   ├── home/
│   ├── search/
│   ├── player/
│   │   ├── player_screen.dart
│   │   ├── mini_player.dart
│   │   └── waveform_visualiser.dart
│   ├── library/
│   ├── profiles/
│   └── settings/
│
└── config/
    ├── secrets.dart.example
    └── secrets.dart          ← gitignored
```
