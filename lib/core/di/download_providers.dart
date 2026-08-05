import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/data/services/download_manager.dart';
import 'package:tuneverse/domain/entities/track.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final isar = ref.watch(isarProvider);
  final youtubeSource = ref.watch(youtubeSourceProvider);
  final manager = DownloadManager(isar, youtubeSource);
  ref.onDispose(manager.dispose);
  return manager;
});

final downloadProgressProvider =
    StreamProvider<DownloadProgress>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.progressStream;
});

final startDownloadProvider = Provider<Future<void> Function(Track)>((ref) {
  final manager = ref.read(downloadManagerProvider);
  return (Track track) async {
    await manager.download(track);
  };
});

final isDownloadedProvider =
    Provider.family<bool, String>((ref, sourceId) {
  // Re-evaluate when any download completes.
  ref.watch(downloadProgressProvider);
  final manager = ref.read(downloadManagerProvider);
  return manager.isDownloaded(sourceId);
});
