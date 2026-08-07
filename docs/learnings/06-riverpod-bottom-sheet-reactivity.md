# Riverpod Bottom Sheet Reactivity

## Problem
The "Add to Playlist" bottom sheet showed a permanent loading spinner when opened from the search screen, even though playlists existed in the database.

## Root Cause
The bottom sheet was opened by a standalone function (not a widget). It captured the provider state once with `ref.read(playlistsProvider)`:

```dart
final playlists = ref.read(playlistsProvider);
```

`ref.read()` captures a **one-time snapshot** of the `AsyncValue`. If the provider hadn't been fetched yet (user never visited the Library tab), the snapshot was `AsyncLoading` — and since the function doesn't subscribe to updates, it stayed loading forever.

## Fix
Wrap the bottom sheet builder in a `Consumer` widget that uses `ref.watch()`:

```dart
builder: (ctx) => Consumer(
  builder: (ctx, sheetRef, _) {
    final playlists = sheetRef.watch(playlistsProvider);
    // ... reactive UI
  },
),
```

## Lesson
Riverpod's `ref.read()` is fire-and-forget. Inside `showModalBottomSheet`, always use a `Consumer` wrapper with `ref.watch()` so the sheet rebuilds when async data arrives. This applies to any UI built outside the widget tree (dialogs, drawers, overlays).
