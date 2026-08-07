# Profile-Playlist Identity Mismatch

## Problem
Profile switching appeared to work (UI highlighted the selected profile) but playlists, favorites, and other profile-scoped data never changed.

## Root Cause
Two disconnected identity systems existed in the codebase:

1. **Isar-based `ProfileEntity`** with auto-incremented `int` IDs (1, 2, 3...)
2. **In-memory `activeProfileIdProvider`** — a `StateProvider<String>` hardcoded to `'default'`

The `switchProfileProvider` toggled `isActive` in Isar and invalidated the profile list, but **never updated `activeProfileIdProvider`**. Since `playlistsProvider` filtered by this provider, playlists were permanently scoped to the `'default'` profile ID — a string that no Isar profile ever produces.

## Fix
1. Added `ref.read(activeProfileIdProvider.notifier).state = profileId.toString()` to `switchProfileProvider`
2. On app startup, resolved the active profile and set the provider to the real ID
3. Migrated existing playlists from `profileId='default'` to the actual profile ID

## Lesson
When two subsystems reference each other via IDs, there must be an explicit bridge that keeps them in sync. Type mismatches (`int` vs `String`) are a strong signal that the bridge was never built.
