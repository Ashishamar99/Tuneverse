# Chromecast Integration in Flutter

## Problem
Needed inbuilt Chromecast casting (like Prime Video / Hotstar) for a music app that streams audio from YouTube.

## Package Choice
`flutter_chrome_cast` (v1.4.6) — wraps the native Google Cast SDK for Android & iOS. Other options considered:
- `cast` (pure Dart CASTV2) — simpler but no native Cast SDK integration, stale since 2024
- Custom platform channels — more work, full control but overkill for this use case

## Bug Workaround
The `flutter_chrome_cast` Dart API has a bug: `GoogleCastOptions.toMap()` omits the required `appId` field that the Android native side needs at `CastContextMethodChannel.setSharedInstance()`. The Android code does `map["appId"] as String` which crashes if missing.

**Fix**: Bypass the broken Dart wrapper and call the method channel directly:
```dart
const channel = MethodChannel('com.felnanuke.google_cast.context');
await channel.invokeMethod('setSharedInstance', {
  'appId': 'CC1AD845',  // Default Media Receiver
  // ... other options
});
```

## Architecture
- **CastService** (singleton) — manages init, discovery, session lifecycle, media loading
- **Riverpod providers** — `isCastingProvider`, `castDevicesProvider`, `castMediaStatusProvider`, `castPositionProvider`
- **CastButton widget** — reusable, shows device picker when tapped, connected indicator when casting
- **Player screen** — shows "Casting to X" banner, routes play/pause/seek to cast service when active
- **playTrackProvider** — intercepts play requests: if casting, sends to Chromecast instead of local just_audio

## Key Details
- Default Media Receiver (`CC1AD845`) works for any audio/video URL — no custom receiver app needed
- YouTube stream URLs work over Cast because they're CDN URLs, not IP-bound
- Stream URLs expire after ~6 hours — re-resolve if cast session is long-running
- AndroidManifest.xml needs `com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME` meta-data pointing to the plugin's `GoogleCastOptionsProvider`
- Cast init is best-effort — wrapped in try/catch since it fails on devices without Google Play Services
