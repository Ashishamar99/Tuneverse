import 'dart:convert';

import 'package:appwrite/appwrite.dart' hide Query;
import 'package:appwrite/appwrite.dart' as aw show Query;
import 'package:appwrite/enums.dart' as enums;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:tuneverse/core/di/appwrite_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/models/profile_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

// ---------------------------------------------------------------------------
// Auth actions
// ---------------------------------------------------------------------------

final signInWithGoogleProvider = Provider((ref) {
  final account = ref.watch(appwriteAccountProvider);
  return () async {
    await account.createOAuth2Session(
      provider: enums.OAuthProvider.google,
      scopes: ['email', 'profile'],
    );
    // Refresh user state after sign-in
    ref.invalidate(appwriteUserProvider);
  };
});

final signOutProvider = Provider((ref) {
  final account = ref.watch(appwriteAccountProvider);
  return () async {
    await account.deleteSession(sessionId: 'current');
    ref.invalidate(appwriteUserProvider);
  };
});

// ---------------------------------------------------------------------------
// Backup
// ---------------------------------------------------------------------------

final backupProvider = Provider((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  final isar = ref.watch(isarProvider);

  return () async {
    final user = await ref.read(appwriteUserProvider.future);
    if (user == null) throw Exception('Not signed in');

    final userId = user.$id;

    // Gather profiles
    final profiles = await isar.profileEntitys.where().findAll();
    final profilesJson = profiles
        .map((p) => {
              'name': p.name,
              'avatarEmoji': p.avatarEmoji,
              'accentColorValue': p.accentColorValue,
              'isActive': p.isActive,
              'favoriteSourceIds': p.favoriteSourceIds,
            })
        .toList();

    // Gather playlists
    final playlists = await isar.playlistEntitys.where().findAll();
    final playlistsJson = playlists
        .map((p) => {
              'profileId': p.profileId,
              'name': p.name,
              'description': p.description,
              'artworkUrl': p.artworkUrl,
              'trackIds': p.trackIds,
            })
        .toList();

    // Gather favorite / played tracks
    final tracks = await isar.trackEntitys
        .filter()
        .isFavoriteEqualTo(true)
        .or()
        .playCountGreaterThan(0)
        .findAll();
    final tracksJson = tracks
        .map((t) => {
              'title': t.title,
              'artist': t.artist,
              'album': t.album,
              'durationMs': t.durationMs,
              'artworkUrl': t.artworkUrl,
              'sourceType': t.sourceType.index,
              'sourceId': t.sourceId,
              'isFavorite': t.isFavorite,
              'playCount': t.playCount,
            })
        .toList();

    // Active profile's favoriteSourceIds
    final activeProfile =
        profiles.where((p) => p.isActive).firstOrNull ?? profiles.first;
    final settingsJson = {
      'favoriteSourceIds': activeProfile.favoriteSourceIds,
    };

    final data = {
      'userId': userId,
      'profiles': jsonEncode(profilesJson),
      'playlists': jsonEncode(playlistsJson),
      'favorites': jsonEncode(tracksJson),
      'settings': jsonEncode(settingsJson),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    // Check if doc exists already
    final existing = await databases.listDocuments(
      databaseId: appwriteDatabaseId,
      collectionId: backupsCollectionId,
      queries: [aw.Query.equal('userId', userId)],
    );

    if (existing.documents.isNotEmpty) {
      // ignore: deprecated_member_use
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: backupsCollectionId,
        documentId: existing.documents.first.$id,
        data: data,
      );
    } else {
      // ignore: deprecated_member_use
      await databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: backupsCollectionId,
        documentId: ID.unique(),
        data: data,
      );
    }
  };
});

// ---------------------------------------------------------------------------
// Restore
// ---------------------------------------------------------------------------

final restoreProvider = Provider((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  final isar = ref.watch(isarProvider);

  return () async {
    final user = await ref.read(appwriteUserProvider.future);
    if (user == null) throw Exception('Not signed in');

    final userId = user.$id;

    final result = await databases.listDocuments(
      databaseId: appwriteDatabaseId,
      collectionId: backupsCollectionId,
      queries: [aw.Query.equal('userId', userId)],
    );

    if (result.documents.isEmpty) {
      throw Exception('No backup found');
    }

    final doc = result.documents.first;
    final docData = doc.data;

    final profilesList =
        (jsonDecode(docData['profiles'] as String) as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final playlistsList =
        (jsonDecode(docData['playlists'] as String) as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final tracksList =
        (jsonDecode(docData['favorites'] as String) as List<dynamic>)
            .cast<Map<String, dynamic>>();

    await isar.writeTxn(() async {
      // Clear existing data
      await isar.profileEntitys.clear();
      await isar.playlistEntitys.clear();
      await isar.trackEntitys.clear();

      // Restore profiles
      for (final p in profilesList) {
        final entity = ProfileEntity()
          ..name = p['name'] as String
          ..avatarEmoji = p['avatarEmoji'] as String
          ..accentColorValue = p['accentColorValue'] as int
          ..isActive = p['isActive'] as bool
          ..favoriteSourceIds = (p['favoriteSourceIds'] as List<dynamic>)
              .cast<String>()
          ..createdAt = DateTime.now();
        await isar.profileEntitys.put(entity);
      }

      // Restore playlists
      for (final p in playlistsList) {
        final entity = PlaylistEntity()
          ..profileId = p['profileId'] as String
          ..name = p['name'] as String
          ..description = p['description'] as String?
          ..artworkUrl = p['artworkUrl'] as String?
          ..trackIds = (p['trackIds'] as List<dynamic>).cast<int>()
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.playlistEntitys.put(entity);
      }

      // Restore tracks
      for (final t in tracksList) {
        final entity = TrackEntity()
          ..title = t['title'] as String
          ..artist = t['artist'] as String
          ..album = t['album'] as String?
          ..durationMs = t['durationMs'] as int?
          ..artworkUrl = t['artworkUrl'] as String?
          ..sourceType = TrackSourceType.values[t['sourceType'] as int]
          ..sourceId = t['sourceId'] as String
          ..isFavorite = t['isFavorite'] as bool
          ..playCount = t['playCount'] as int;
        await isar.trackEntitys.put(entity);
      }
    });
  };
});

// ---------------------------------------------------------------------------
// Check backup exists
// ---------------------------------------------------------------------------

final checkBackupExistsProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(appwriteUserProvider.future);
  if (user == null) return false;

  final databases = ref.watch(appwriteDatabasesProvider);
  final result = await databases.listDocuments(
    databaseId: appwriteDatabaseId,
    collectionId: backupsCollectionId,
    queries: [aw.Query.equal('userId', user.$id)],
  );

  return result.documents.isNotEmpty;
});
