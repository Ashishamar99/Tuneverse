import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

final toggleFavoriteProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);

  return (Track track) async {
    bool nowFavorite = false;
    await isar.writeTxn(() async {
      var entity = await isar.trackEntitys
          .getBySourceIdSourceType(track.sourceId, track.sourceType);

      if (entity == null) {
        entity = TrackEntity.fromDomain(track)..isFavorite = true;
        nowFavorite = true;
      } else {
        entity.isFavorite = !entity.isFavorite;
        nowFavorite = entity.isFavorite;
      }

      await isar.trackEntitys.put(entity);
    });

    ref.invalidate(favoritesProvider);
    ref.invalidate(isFavoriteProvider(track.sourceId));
    return nowFavorite;
  };
});

final isFavoriteProvider = FutureProvider.family<bool, String>((ref, sourceId) async {
  final isar = ref.watch(isarProvider);
  final entity = await isar.trackEntitys
      .filter()
      .sourceIdEqualTo(sourceId)
      .isFavoriteEqualTo(true)
      .findFirst();
  return entity != null;
});

final favoritesProvider = FutureProvider<List<Track>>((ref) async {
  final isar = ref.watch(isarProvider);
  final entities = await isar.trackEntitys
      .filter()
      .isFavoriteEqualTo(true)
      .sortByTitle()
      .findAll();
  return entities.map((e) => e.toDomain()).toList();
});
