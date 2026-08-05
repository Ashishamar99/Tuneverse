import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/data/sources/local/local_file_source.dart';
import 'package:tuneverse/domain/entities/track.dart';

final localFileSourceProvider = Provider<LocalFileSource>((ref) {
  final isar = ref.watch(isarProvider);
  return LocalFileSource(isar);
});

final audioPermissionProvider = FutureProvider<bool>((ref) async {
  var status = await Permission.audio.request();
  if (status.isGranted) return true;

  // Fallback for Android 12 and below where Permission.audio is unavailable.
  status = await Permission.storage.request();
  return status.isGranted;
});

final localTracksProvider = FutureProvider<List<Track>>((ref) async {
  final granted = await ref.watch(audioPermissionProvider.future);
  if (!granted) return [];
  final source = ref.watch(localFileSourceProvider);
  return source.scanDevice();
});

final playLocalTrackProvider = Provider((ref) {
  return (Track track) async {
    final handler = ref.read(audioHandlerProvider);
    ref.read(nowPlayingProvider.notifier).state = track;

    final uri = Uri.file(track.localPath!);
    final mediaItem = MediaItem(
      id: track.sourceId,
      title: track.title,
      artist: track.artist,
      duration: track.duration,
    );

    await handler.playTrack(mediaItem, uri);
    handler.recordPlay(track);
  };
});
