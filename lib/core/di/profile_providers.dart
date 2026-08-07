import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/data/models/profile_entity.dart';
import 'package:tuneverse/data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(isarProvider));
});

final allProfilesProvider = FutureProvider<List<ProfileEntity>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  await repo.ensureDefault();
  return repo.getAll();
});

final activeProfileProvider = FutureProvider<ProfileEntity>((ref) async {
  final profiles = await ref.watch(allProfilesProvider.future);
  return profiles.firstWhere((p) => p.isActive);
});

final switchProfileProvider = Provider<Future<void> Function(int)>((ref) {
  return (int profileId) async {
    ref.read(activeProfileIdProvider.notifier).state = profileId.toString();
    await ref.read(profileRepositoryProvider).switchTo(profileId);
    ref.invalidate(allProfilesProvider);
  };
});
