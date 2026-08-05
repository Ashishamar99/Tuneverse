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

| Phase | What ships |
|---|---|
| 1 — Foundation | Flutter project, Isar schema, audio service, local file playback |
| 2 — YouTube Engine | Search + stream + play YouTube audio |
| 3 — UI Shell | Design system, navigation, mini player, full player |
| 4 — Universal Links | Spotify/Amazon/YouTube link → plays audio |
| 5 — Local Files | Storage scan, local playback, playlists |
| 6 — Platform | Android Auto, Bluetooth, Chromecast |
| 7 — Visualiser | Fluid sine wave on player screen |
| 8 — Profiles | Family profiles, per-profile library |
| 9 — Polish | Transitions, downloads, performance |

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
│   ├── core/           # DI, router, theme, constants
│   ├── data/           # Repositories, data sources, Isar models
│   ├── domain/         # Entities, use cases, interfaces
│   └── presentation/   # Screens, widgets, Riverpod providers
├── docs/
│   ├── architecture.md
│   ├── implementation-plan.md
│   └── superpowers/specs/
└── android/            # Android-specific config (AndroidAuto, etc.)
```

---

## Docs

- [Architecture deep-dive](docs/architecture.md)
- [Implementation plan](docs/implementation-plan.md)
- [Design spec](docs/superpowers/specs/2026-08-06-tuneverse-design.md)

---

*Personal/family use. Not for distribution.*
