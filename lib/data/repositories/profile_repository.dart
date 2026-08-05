import 'package:isar/isar.dart';
import 'package:tuneverse/core/constants/app_constants.dart';
import 'package:tuneverse/data/models/profile_entity.dart';

class ProfileRepository {
  ProfileRepository(this._isar);

  final Isar _isar;

  Future<List<ProfileEntity>> getAll() {
    return _isar.profileEntitys.where().findAll();
  }

  Future<ProfileEntity?> getActive() {
    return _isar.profileEntitys.filter().isActiveEqualTo(true).findFirst();
  }

  Future<ProfileEntity> create(
    String name,
    String emoji,
    int colorValue,
  ) async {
    final profile = ProfileEntity()
      ..name = name
      ..avatarEmoji = emoji
      ..accentColorValue = colorValue
      ..createdAt = DateTime.now()
      ..isActive = false;

    await _isar.writeTxn(() async {
      await _isar.profileEntitys.put(profile);
    });

    return profile;
  }

  Future<void> update(
    int id,
    String name,
    String emoji,
    int colorValue,
  ) async {
    await _isar.writeTxn(() async {
      final profile = await _isar.profileEntitys.get(id);
      if (profile == null) return;
      profile
        ..name = name
        ..avatarEmoji = emoji
        ..accentColorValue = colorValue;
      await _isar.profileEntitys.put(profile);
    });
  }

  Future<void> switchTo(int profileId) async {
    await _isar.writeTxn(() async {
      final all = await _isar.profileEntitys.where().findAll();
      for (final p in all) {
        p.isActive = p.id == profileId;
      }
      await _isar.profileEntitys.putAll(all);
    });
  }

  /// Returns false if deletion was refused (last remaining profile).
  Future<bool> delete(int profileId) async {
    final all = await getAll();
    if (all.length <= 1) return false;

    final wasActive = all.any((p) => p.id == profileId && p.isActive);

    await _isar.writeTxn(() async {
      await _isar.profileEntitys.delete(profileId);
    });

    if (wasActive) {
      final remaining = await getAll();
      if (remaining.isNotEmpty) {
        await switchTo(remaining.first.id);
      }
    }

    return true;
  }

  Future<ProfileEntity> ensureDefault() async {
    final existing = await getAll();
    if (existing.isNotEmpty) {
      final active = existing.where((p) => p.isActive).firstOrNull;
      if (active != null) return active;
      await switchTo(existing.first.id);
      return existing.first;
    }

    final profile = ProfileEntity()
      ..name = AppConstants.defaultProfileName
      ..avatarEmoji = AppConstants.defaultProfileEmoji
      ..accentColorValue = 0xFF6C63FF
      ..createdAt = DateTime.now()
      ..isActive = true;

    await _isar.writeTxn(() async {
      await _isar.profileEntitys.put(profile);
    });

    return profile;
  }
}
