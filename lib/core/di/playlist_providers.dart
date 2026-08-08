import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

final playlistsProvider = FutureProvider<List<PlaylistEntity>>((ref) async {
  final isar = ref.watch(isarProvider);
  final profileId = ref.watch(activeProfileIdProvider);
  return isar.playlistEntitys
      .filter()
      .profileIdEqualTo(profileId)
      .sortByUpdatedAtDesc()
      .findAll();
});

final playlistTracksProvider =
    FutureProvider.family<List<Track>, int>((ref, playlistId) async {
  final isar = ref.watch(isarProvider);
  final playlist = await isar.playlistEntitys.get(playlistId);
  if (playlist == null) return [];

  final tracks = <Track>[];
  for (final id in playlist.trackIds) {
    final entity = await isar.trackEntitys.get(id);
    if (entity != null) {
      tracks.add(entity.toDomain());
    }
  }
  return tracks;
});

final createPlaylistProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  final profileId = ref.watch(activeProfileIdProvider);

  return (String name, {String? description}) async {
    final now = DateTime.now();
    final playlist = PlaylistEntity()
      ..profileId = profileId
      ..name = name
      ..description = description
      ..createdAt = now
      ..updatedAt = now;

    await isar.writeTxn(() async {
      await isar.playlistEntitys.put(playlist);
    });
    ref.invalidate(playlistsProvider);
    return playlist;
  };
});

final addToPlaylistProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);

  return (int playlistId, Track track) async {
    await isar.writeTxn(() async {
      var entity = await isar.trackEntitys
          .getBySourceIdSourceType(track.sourceId, track.sourceType);
      if (entity == null) {
        entity = TrackEntity.fromDomain(track);
        await isar.trackEntitys.put(entity);
      }

      final playlist = await isar.playlistEntitys.get(playlistId);
      if (playlist == null) return;

      if (!playlist.trackIds.contains(entity.id)) {
        playlist.trackIds = [...playlist.trackIds, entity.id];
        playlist.updatedAt = DateTime.now();
        await isar.playlistEntitys.put(playlist);
      }
    });
    ref.invalidate(playlistTracksProvider(playlistId));
    ref.invalidate(playlistsProvider);
  };
});

final removeFromPlaylistProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);

  return (int playlistId, int trackIsarId) async {
    await isar.writeTxn(() async {
      final playlist = await isar.playlistEntitys.get(playlistId);
      if (playlist == null) return;
      playlist.trackIds = playlist.trackIds.where((id) => id != trackIsarId).toList();
      playlist.updatedAt = DateTime.now();
      await isar.playlistEntitys.put(playlist);
    });
    ref.invalidate(playlistTracksProvider(playlistId));
    ref.invalidate(playlistsProvider);
  };
});

final lastPlayedInPlaylistProvider =
    StateProvider<Map<int, String>>((ref) => {});

final renamePlaylistProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);

  return (int playlistId, String newName) async {
    await isar.writeTxn(() async {
      final playlist = await isar.playlistEntitys.get(playlistId);
      if (playlist == null) return;
      playlist.name = newName;
      playlist.updatedAt = DateTime.now();
      await isar.playlistEntitys.put(playlist);
    });
    ref.invalidate(playlistsProvider);
  };
});

final reorderPlaylistProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);

  return (int playlistId, List<int> newTrackIds) async {
    await isar.writeTxn(() async {
      final playlist = await isar.playlistEntitys.get(playlistId);
      if (playlist == null) return;
      playlist.trackIds = newTrackIds;
      playlist.updatedAt = DateTime.now();
      await isar.playlistEntitys.put(playlist);
    });
    ref.invalidate(playlistTracksProvider(playlistId));
    ref.invalidate(playlistsProvider);
  };
});

final deletePlaylistProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);

  return (int playlistId) async {
    await isar.writeTxn(() async {
      await isar.playlistEntitys.delete(playlistId);
    });
    ref.invalidate(playlistsProvider);
  };
});
