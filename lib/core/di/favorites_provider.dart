import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:tuneverse/core/di/profile_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/data/models/profile_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

final toggleFavoriteProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);

  return (Track track) async {
    bool nowFavorite = false;
    final profileId = int.tryParse(ref.read(activeProfileIdProvider));

    await isar.writeTxn(() async {
      var entity = await isar.trackEntitys
          .getBySourceIdSourceType(track.sourceId, track.sourceType);

      if (entity == null) {
        entity = TrackEntity.fromDomain(track);
        await isar.trackEntitys.put(entity);
      }

      if (profileId != null) {
        final profile = await isar.profileEntitys.get(profileId);
        if (profile != null) {
          final ids = [...profile.favoriteSourceIds];
          if (ids.contains(track.sourceId)) {
            ids.remove(track.sourceId);
            nowFavorite = false;
          } else {
            ids.add(track.sourceId);
            nowFavorite = true;
          }
          profile.favoriteSourceIds = ids;
          await isar.profileEntitys.put(profile);
        }
      }
    });

    ref.invalidate(favoritesProvider);
    ref.invalidate(isFavoriteProvider(track.sourceId));
    return nowFavorite;
  };
});

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, sourceId) async {
  final isar = ref.watch(isarProvider);
  final profileId = int.tryParse(ref.watch(activeProfileIdProvider));
  if (profileId == null) return false;
  final profile = await isar.profileEntitys.get(profileId);
  return profile?.favoriteSourceIds.contains(sourceId) ?? false;
});

final favoritesProvider = FutureProvider<List<Track>>((ref) async {
  final isar = ref.watch(isarProvider);
  final profileId = int.tryParse(ref.watch(activeProfileIdProvider));
  if (profileId == null) return [];

  final profile = await isar.profileEntitys.get(profileId);
  if (profile == null) return [];

  final tracks = <Track>[];
  for (final sourceId in profile.favoriteSourceIds) {
    final entity = await isar.trackEntitys
        .filter()
        .sourceIdEqualTo(sourceId)
        .findFirst();
    if (entity != null) tracks.add(entity.toDomain());
  }
  return tracks;
});
