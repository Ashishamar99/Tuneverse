# TuneVerse

A music super-app for Android (and later iOS/desktop) that plays music from any source — paste a Spotify link, an Amazon Music link, a YouTube Music link, or play files straight from your phone. Built with Flutter.

---

## What It Does

- **Universal link handler** — paste any Spotify, Amazon Music, or YouTube Music link and it plays
- **YouTube as audio backend** — resolves any track to the best YouTube audio stream
- **Local files** — scan your device storage, play and organise into playlists
- **Full player** — shuffle, loop (one/all/off), queue, seek, crossfade
- **Fluid sine wave visualiser** — album-art-reactive, layered sine waves at 60fps
- **Chromecast & Bluetooth** — cast to TV/speaker, proper audio focus handling
- **Android Auto** — full media session with browsable content
- **Family profiles** — Netflix-style profile switcher, each with its own library and playlists
- **Downloads** — save tracks for offline playback
- **Search** — unified search across local library and YouTube

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart) — Android-first, cross-platform later |
| Audio engine | `just_audio` + `audio_service` |
| YouTube source | `youtube_explode_dart` |
| Local media | `on_audio_query` |
| Database | Isar |
| State management | Riverpod |
| Navigation | Go Router (deep links for universal handler) |
| Audio visualiser | `audio_visualizer` + custom `CustomPainter` |
| Dynamic theming | `palette_generator` (colours from album art) |
| Downloads | `dio` + `youtube_explode_dart` |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                │
│  Home │ Search │ Player │ Library │ Profiles        │
│  (Riverpod + Go Router)                             │
├─────────────────────────────────────────────────────┤
│                    DOMAIN LAYER                     │
│  PlaybackUseCase │ SearchUseCase │ ResolveUseCase   │
│  PlaylistUseCase │ DownloadUseCase                  │
├──────────────┬──────────────────┬───────────────────┤
│  SOURCE LAYER│  PLATFORM LAYER  │   DATA LAYER      │
│              │                  │                   │
│ TrackSource  │ AudioService     │ Isar DB           │
│ ├─YouTube    │ AndroidAuto      │ ├─TrackEntity     │
│ ├─LocalFile  │ Bluetooth Focus  │ ├─PlaylistEntity  │
│ └─Resolved   │ Chromecast       │ ├─ProfileEntity   │
│   (Spotify/  │                  │ └─QueueEntity     │
│    Amazon→YT)│                  │                   │
└──────────────┴──────────────────┴───────────────────┘
```

See [`docs/architecture.md`](docs/architecture.md) for full detail.

---

## Build Phases

| Phase | What ships | Status |
|---|---|---|
| 1 — Foundation | Flutter project, Isar schema, audio service, UI shell | Done |
| 2 — YouTube Engine | Search + stream + play YouTube audio | Done |
| 3 — UI Shell | Full player with controls, mini player, ambient glow | Done |
| 4 — Universal Links | Spotify/Amazon/YouTube link resolver → plays via YouTube | Done |
| 5 — Local Files | MediaStore scan, local playback, library screen | Done |
| 6 — Platform | Android Auto content tree, audio session, play history | Done |
| 7 — Visualiser | Fluid sine wave visualiser on player screen | Done |
| 8 — Profiles | Netflix-style family profiles with emoji + color picker | Done |
| 9 — Polish | Downloads, Hero animations, enhanced transitions | Done |

---

## Setup

### Prerequisites
- Flutter 3.x
- Android Studio / Android SDK
- A Spotify Developer app (for link resolution) — [create one here](https://developer.spotify.com/dashboard)

### Environment Variables

Copy the example secrets file and fill in your keys:

```bash
cp lib/config/secrets.dart.example lib/config/secrets.dart
```

`lib/config/secrets.dart` is gitignored. Never commit it.

### Run

```bash
flutter pub get
flutter run
```

---

## Repository Structure

```
tuneverse/
├── lib/
│   ├── config/              # secrets.dart (gitignored), example template
│   ├── core/
│   │   ├── constants/       # App constants (durations, limits)
│   │   ├── di/              # Riverpod providers (audio, download, local, profile, resolver, youtube)
│   │   ├── router/          # Go Router with deep links + transitions
│   │   └── theme/           # Dark theme, dynamic accent colors
│   ├── data/
│   │   ├── models/          # Isar collections (track, playlist, profile, queue)
│   │   ├── platform/        # AudioHandler with Android Auto content tree
│   │   ├── repositories/    # ProfileRepository (Isar CRUD)
│   │   ├── services/        # DownloadManager (queued Dio downloads)
│   │   └── sources/
│   │       ├── local/       # LocalFileSource (MediaStore + on_audio_query)
│   │       ├── resolver/    # LinkParser, SpotifyFetcher, AmazonFetcher, UniversalResolver
│   │       └── youtube/     # YouTubeSource (youtube_explode_dart)
│   ├── domain/
│   │   ├── entities/        # Track (with TrackSourceType enum)
│   │   └── interfaces/      # TrackSource abstract interface
│   └── presentation/
│       ├── home/            # Home screen with quick actions, paste-link dialog
│       ├── library/         # Library with Local + Playlists tabs
│       ├── player/          # Full player + WaveformVisualiser
│       ├── profiles/        # Netflix-style profile selector
│       ├── search/          # YouTube search with download buttons
│       ├── settings/        # Settings screen
│       └── shared/widgets/  # MiniPlayer, ScaffoldWithNav
├── docs/
│   ├── architecture.md
│   └── implementation-plan.md
└── android/                 # Android config (Android Auto, intent filters)
```

---

## Docs

- [Architecture deep-dive](docs/architecture.md)
- [Implementation plan](docs/implementation-plan.md)
- [Design spec](docs/superpowers/specs/2026-08-06-tuneverse-design.md)

---

*Personal/family use. Not for distribution.*
