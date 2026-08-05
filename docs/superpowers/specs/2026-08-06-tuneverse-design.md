---
name: tuneverse-music-app-design
description: Full design spec for TuneVerse — a Flutter music super-app for personal/family use with YouTube backend, universal link resolver, fluid visualiser, Android Auto, and family profiles
metadata:
  type: project
---

# TuneVerse Design Spec

**Date:** 2026-08-06  
**Status:** Approved  
**Platform:** Android-first (Flutter, cross-platform later)  
**Use case:** Personal / family use

---

## Problem

Music is spread across Spotify, Amazon Music, YouTube Music, and local files. There's no single app that plays all of them without switching apps, dealing with ads, or losing your queue. We want one app that handles everything.

---

## Solution

A Flutter music super-app that:
1. Accepts any music link (Spotify, Amazon Music, YouTube Music) and plays it
2. Plays local phone storage files in the same queue
3. Uses YouTube as the universal audio backend (resolving all external links to YouTube streams)
4. Has a beautiful, minimal dark UI with dynamic album-art theming and a fluid sine wave visualiser
5. Integrates with Android Auto, Bluetooth, and Chromecast
6. Supports Netflix-style family profiles

---

## Approach Chosen

**Shallow Fork of Namida** — extract Namida's battle-tested packages and architecture patterns (just_audio, audio_service, youtube_explode_dart, Isar) but build the UI and feature set completely fresh. This gives us a proven audio engine without inheriting Namida's complex UI or heavy feature surface.

---

## Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Framework | Flutter | Cross-platform, Dart, single codebase |
| Audio | just_audio + audio_service | Battle-tested, Android Auto compatible |
| YouTube | youtube_explode_dart | InnerTube wrapper, no API key required |
| Local media | on_audio_query | Android MediaStore, metadata extraction |
| Database | Isar | Flutter-native, embedded, very fast |
| State | Riverpod | Composable, async-friendly, testable |
| Navigation | Go Router | Deep link support (critical for universal handler) |
| Visualiser | audio_visualizer + CustomPainter | HTTP stream support, custom sine wave render |
| Dynamic theme | palette_generator | Album art → accent colour |
| Downloads | dio | Stream URL → file with progress tracking |
| Secrets | flutter_secure_storage + .gitignored dart file | No secrets in code |

---

## Architecture

Clean Architecture (3 layers):

```
Presentation → Domain → Data/Source
```

- **Presentation**: Flutter widgets, Riverpod providers/notifiers, Go Router
- **Domain**: Use cases (Playback, Search, Resolve, Playlist, Download, Profile)
- **Data**: TrackSource implementations, Isar repositories, platform bridges

All audio sources implement a single `TrackSource` interface. Adding a new source (e.g. SoundCloud) never touches playback or UI.

---

## Key Design Decisions

### 1. YouTube as Universal Backend

Spotify and Amazon Music APIs don't allow audio streaming. So when a user shares a Spotify link, we:
1. Call Spotify Web API for metadata (title, artist, duration)
2. Search YouTube for best match
3. Score candidates by title similarity + artist match + duration proximity
4. Stream the winner

This covers all sources. YouTube Music links resolve directly. Local files play from storage. Everything lands in the same queue.

### 2. Secrets Strategy

Spotify API credentials (Client ID + Secret) are required for metadata fetching. They:
- Live in `lib/config/secrets.dart` (gitignored)
- Are provided by the user (free Spotify Developer account)
- Are stored at runtime in Android Keystore via `flutter_secure_storage`
- Use Client Credentials flow (no user Spotify login needed)

### 3. Android Auto via audio_service

`audio_service` implements `MediaBrowserServiceCompat` which is Android Auto's required interface. We define a content hierarchy (Playlists / Recently Played / Library) and handle all media actions. This is the cleanest path — no custom platform channels needed.

### 4. Visualiser Approach

`audio_visualizer` supports HTTP audio streams (YouTube URLs) and outputs FFT amplitude data. We render three layered sine waves via `CustomPainter` at 60fps:
- Amplitude from FFT (exponential moving average smoothing)
- Phase offset advances with playback position
- Colours derived from album art via `palette_generator`

Wrapped in `RepaintBoundary` to avoid full tree repaints.

### 5. Profiles as Data Scoping

Profiles are not authentication — they're data scoping. Every Isar entity (playlist, queue, history) carries a `profileId`. Switching profiles reloads all Riverpod providers with the new profile's `profileId`. No complex auth, no server.

---

## UI Design

### Visual Language
- Near-black background (#080808)
- Surface: #141414 / #1E1E1E (elevated)
- Accent: dynamic from album art (palette_generator)
- Typography: Plus Jakarta Sans
- Corner radius: 16dp standard, 32dp album art
- Motion: spring physics for controls, easeOutCubic for navigation

### Navigation
4-tab bottom nav: Home → Search → Library → Profile

### Player Screen
- Full-screen, swipe down to dismiss
- Large album art with ambient blur glow behind
- Fluid sine wave visualiser between art and controls
- Seek bar with position and duration
- Controls: shuffle, prev, play/pause, next, loop
- Volume slider + Cast button
- Mini player always visible above nav bar

---

## Build Sequence

| Phase | Deliverable |
|---|---|
| 1 | Foundation: audio service + local playback |
| 2 | YouTube audio streaming |
| 3 | Full UI shell + design system |
| 4 | Universal link resolver |
| 5 | Local library full integration |
| 6 | Android Auto, Bluetooth, Chromecast |
| 7 | Fluid sine wave visualiser |
| 8 | Family profiles |
| 9 | Downloads, polish, performance |

---

## Out of Scope (this version)

- iOS / macOS / desktop (Android-first)
- User accounts / cloud sync
- Social features
- Lyrics (could be Phase 10)
- Equaliser (could be Phase 10)
- Streaming from SoundCloud / JioSaavn (architecture supports adding later)
