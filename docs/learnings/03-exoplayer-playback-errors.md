# ExoPlayer Playback Error Handling

## Problem
When ExoPlayer fails to play audio (e.g., 403 from YouTube), the error is
silently swallowed — the user sees nothing, the app appears frozen.

## Fix
1. Wrap `playTrack` in try-catch and surface errors via a Riverpod
   `playbackErrorProvider`
2. Show a `SnackBar` in the search screen when `playbackErrorProvider` has a
   value after a play attempt

```dart
// youtube_providers.dart
final playbackErrorProvider = StateProvider<String?>((ref) => null);

// In playTrackProvider:
try {
  await handler.playTrack(mediaItem, uri);
} catch (e) {
  ref.read(playbackErrorProvider.notifier).state = e.toString();
}
```

```dart
// search_screen.dart — onTap:
await ref.read(playTrackProvider)(track);
final error = ref.read(playbackErrorProvider);
if (error != null && context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

## Lesson
Always surface audio playback errors to the UI. ExoPlayer errors propagate as
exceptions through just_audio's `setAudioSource` or `play` methods — they don't
fire silently.
