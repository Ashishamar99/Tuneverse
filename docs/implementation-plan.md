# TuneVerse — Implementation Plan

## Strategy

Build incrementally. Each phase produces a working, committable app. Later phases add features on top without breaking earlier ones. Ralph Loop is used for phases with clear success criteria and natural iteration.

---

## Phase 1 — Foundation

**Goal:** App launches, plays a local audio file, persists data across restarts.

**Tasks:**
1. `flutter create tuneverse` with `com.ashtroid.tuneverse` package ID
2. Add all core dependencies to `pubspec.yaml`
3. Set up Clean Architecture folder structure
4. Define Isar schema: `TrackEntity`, `PlaylistEntity`, `ProfileEntity`, `QueueEntity`
5. Implement `audio_service` `AudioHandler` boilerplate
6. Wire `just_audio` player to `AudioHandler`
7. Implement `LocalFileSource` using `on_audio_query`
8. Scan device storage on first launch, index into Isar
9. Play a local file end-to-end (no UI polish — bare bones test screen)
10. Set up `secrets.dart.example` and `.gitignore`

**Success criteria:** App launches, finds local music files, plays one track, shows lock-screen controls.

**Ralph Loop:** No — too much foundational work requiring human judgment.

**Commit:** `feat: Phase 1 — foundation, local playback, Isar schema`

---

## Phase 2 — YouTube Engine

**Goal:** Search YouTube, select best audio stream, play it.

**Tasks:**
1. Add `youtube_explode_dart` dependency
2. Implement `YouTubeSource.search(query)` — returns list of `TrackEntity`
3. Implement `YouTubeSource.getStreamUri(track)` — picks best audio-only stream (prefer opus/m4a 128kbps+)
4. Wire to `just_audio` via `AudioSource.uri()`
5. Handle geo-restrictions and errors gracefully
6. Cache stream URIs in memory (they expire after ~6h)
7. Basic search screen (unstyled) to test

**Success criteria:** Type a song name, get results, tap to play YouTube audio in the background.

**Ralph Loop:** No — stream URL selection logic needs careful tuning.

**Commit:** `feat: Phase 2 — YouTube audio source`

---

## Phase 3 — UI Shell

**Goal:** Full design system, navigation, mini player, player screen (no visualiser yet).

**Tasks:**
1. Set up `ThemeData` with design tokens (dark, Plus Jakarta Sans, `#080808` bg)
2. `palette_generator` integration — extract colours from album art on track change
3. Go Router setup with all routes + deep link placeholder
4. Bottom navigation: Home, Search, Library, Profile
5. `MiniPlayer` widget — persistent above bottom nav, tap to open full player
6. `PlayerScreen` — full layout (art, title, controls, seek bar), spring animations on controls
7. `HomeScreen` — recent tracks, recently played playlists
8. `SearchScreen` — search input with debounce, results list
9. `LibraryScreen` — local tracks, playlists tabs
10. `ProfileScreen` — profile avatar + settings entry point

**Success criteria:** Visually complete shell, music plays when a search result is tapped, mini player shows and animates, full player opens with Hero animation on album art.

**Ralph Loop:** Partial — use for control animation polish and Hero transition tuning.

**Commit:** `feat: Phase 3 — UI shell, design system, navigation`

---

## Phase 4 — Universal Link Resolver

**Goal:** Paste/share any Spotify, Amazon Music, or YouTube Music link → plays the track.

**Tasks:**
1. Implement `LinkParser` — regex-based, identifies platform + ID from URL
2. `SpotifyFetcher` — Spotify Web API Client Credentials token fetch + track metadata
3. `AmazonFetcher` — fetch share URL, parse `og:title` + `og:description` HTML meta tags
4. `YouTubeMusicFetcher` — resolve YouTube Music URL directly to video ID
5. `BestMatchSelector` — score YouTube search results by title similarity, artist match, duration proximity
6. `ResolvedSource` — wraps the above into a `TrackSource`
7. `DeepLinkHandler` in Go Router — intercepts share intents, routes to `ResolveUseCase`
8. Android `intent-filter` in `AndroidManifest.xml` for `VIEW` action on Spotify/Amazon/YouTube domains
9. Spotify credentials in `secrets.dart`, stored at runtime in `flutter_secure_storage`
10. End-to-end test: share Spotify link → app opens → track plays

**Success criteria:**
- `https://open.spotify.com/track/...` → correct song plays
- `https://music.amazon.com/albums/...` → best match plays
- `https://music.youtube.com/watch?v=...` → direct play
- Playlist links → entire playlist queued

**Ralph Loop:** YES — ideal. Well-defined success criteria, needs iteration on match scoring.

**Commit:** `feat: Phase 4 — universal link resolver (Spotify, Amazon, YouTube Music)`

---

## Phase 5 — Local Files Full Integration

**Goal:** Full local library — browse, search, add to playlists, play offline.

**Tasks:**
1. Request `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` permissions properly
2. Full `LocalFileSource` with metadata: title, artist, album, artwork extraction
3. Library screen: tracks, albums, artists views
4. Playlist creation UI + add local tracks to playlists
5. Folder browsing view
6. `LocalFileSource` search in Isar (full-text)
7. Mix local + YouTube tracks in the same playlist

**Success criteria:** Browse local library, create playlist mixing local + YouTube tracks, search finds local results instantly.

**Ralph Loop:** YES — permissions and MediaStore edge cases benefit from iteration.

**Commit:** `feat: Phase 5 — full local library integration`

---

## Phase 6 — Platform Integrations

**Goal:** Android Auto, Bluetooth audio focus, Chromecast.

### 6a — Android Auto
1. `automotive_app_desc.xml` — declare as media app
2. Content hierarchy in `AudioHandler.onLoadChildren`: Playlists, Recently Played, Library
3. Handle `MediaAction.play`, `pause`, `skipToNext`, `skipToPrevious`, `seek`, `setShuffleMode`
4. Test in Android Auto Desktop Head Unit (DHU) emulator

### 6b — Bluetooth & Audio Focus
1. Handle `AUDIO_BECOMING_NOISY` — pause playback when headphones disconnect
2. `AudioFocus` request via `audio_service` — duck/pause on call, resume after
3. `BluetoothHeadsetPlugin` if needed for connect/disconnect events

### 6c — Chromecast
1. Add `cast` Flutter package
2. `CastManager` — discover devices, start session, send media load request
3. Cast button in player screen (top-right)
4. Handle cast session disconnect gracefully

**Success criteria:**
- Android Auto: music controls visible and working while driving (DHU test)
- Headphones disconnect: playback pauses
- Cast: track name + art appear on TV, controls work from phone

**Ralph Loop:** YES for 6a (AndroidAuto DHU iteration) and 6c (Cast session handling).

**Commit:** `feat: Phase 6 — Android Auto, Bluetooth focus, Chromecast`

---

## Phase 7 — Fluid Sine Wave Visualiser

**Goal:** Beautiful, reactive fluid sine wave on the player screen, driven by real audio data.

**Tasks:**
1. Integrate `audio_visualizer` package — attach to audio stream URL
2. `WaveformVisualiserController` Riverpod provider — exposes FFT amplitude stream
3. `SineWavePainter` (CustomPainter):
   - Three layered sine waves
   - Wave 1: frequency `f`, opacity 0.9, accent colour
   - Wave 2: frequency `f * 1.3`, opacity 0.5, accent colour lightened 20%
   - Wave 3: frequency `f * 0.7`, opacity 0.3, accent colour darkened 20%
   - Phase offset advances with `playback.position`
   - Amplitude from FFT (smoothed with exponential moving average)
4. `RepaintBoundary` wrapping the painter for 60fps without full tree repaints
5. Integrate into `PlayerScreen` between album art and controls
6. Graceful fallback (static gentle wave) when FFT data is unavailable (e.g. local file edge case)

**Success criteria:** Wave is visually smooth at 60fps, reacts to bass/treble changes, changes colour with album art, doesn't stutter during track transitions.

**Ralph Loop:** YES — visual quality iteration, perfect for loop refinement.

**Commit:** `feat: Phase 7 — fluid sine wave visualiser`

---

## Phase 8 — Family Profiles

**Goal:** Netflix-style profile switcher; each profile has its own library and playlists.

**Tasks:**
1. `ProfileScreen` — grid of up to 6 profiles, "+ Add" button
2. Profile creation: name + emoji avatar + accent colour picker
3. `ProfileUseCase` — switch active profile (updates Isar, reloads Riverpod state)
4. Profile selector on app launch (optional, toggleable in settings)
5. All playlists, history, queue scoped to active `profileId`
6. Profile editing + deletion (with confirmation)

**Success criteria:** Create two profiles, add different playlists to each, switch profiles — each sees only its own data.

**Ralph Loop:** YES.

**Commit:** `feat: Phase 8 — family profiles`

---

## Phase 9 — Polish, Downloads, Performance

**Goal:** Ship-ready quality — smooth transitions, offline downloads, fast cold start.

### 9a — Transitions & Animations
- Hero animation: album art from list → player screen
- Page transitions: shared element + fade
- Mini player slide-up on first track play
- Control button spring animations on tap
- Playlist item reorder drag animation

### 9b — Downloads
1. `DownloadUseCase` — fetch YouTube stream URL via `youtube_explode_dart`, download with `dio`
2. Progress UI (circular progress on track art in Library)
3. Store file in `getApplicationDocumentsDirectory()/downloads/`
4. Update `TrackEntity.localPath` + `downloadedAt` in Isar
5. Playback automatically uses local file when available (no stream needed)

### 9c — Performance
- Isar indexes on frequently queried fields (artist, title, profileId)
- Image caching with `cached_network_image`
- `audio_service` startup time audit
- Cold start target: <2s to first frame

**Ralph Loop:** YES for 9a (animations) and 9c (perf).

**Commit:** `feat: Phase 9 — polish, downloads, performance`

---

## Dependency List (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Audio
  just_audio: ^0.9.40
  audio_service: ^0.18.15
  just_audio_background: ^0.0.1-beta.12

  # YouTube
  youtube_explode_dart: ^2.3.0

  # Local media
  on_audio_query: ^2.9.0

  # Database
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.3

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.7

  # Visualiser
  audio_visualizer: ^1.0.0

  # Dynamic theming
  palette_generator: ^0.3.3+3

  # Network
  dio: ^5.7.0
  cached_network_image: ^3.3.1

  # Secrets
  flutter_secure_storage: ^9.2.2

  # Casting
  cast: ^2.1.0

  # Permissions
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  isar_generator: ^3.1.0
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.12
  flutter_lints: ^4.0.0
```

---

## Git Commit Convention

```
feat: Phase N — short description
fix: description of bug fixed
refactor: description
docs: description
```

Each phase gets one or more commits. Never commit `secrets.dart`.
