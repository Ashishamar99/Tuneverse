import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/models/profile_entity.dart';
import 'package:tuneverse/data/models/queue_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/data/platform/audio_handler.dart';

// Isar is opened once at app start and stored here.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be overridden at app startup');
});

// AudioHandler is initialised once via audio_service and stored here.
final audioHandlerProvider = Provider<TuneVerseAudioHandler>((ref) {
  throw UnimplementedError('AudioHandler must be overridden at app startup');
});

// Convenience: the underlying just_audio player, via the handler.
final audioPlayerProvider = Provider((ref) {
  return ref.watch(audioHandlerProvider).player;
});

// Currently active profile ID. Defaults to 'default'.
final activeProfileIdProvider = StateProvider<String>((ref) => 'default');

Future<(Isar, TuneVerseAudioHandler)> initServices() async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [
      TrackEntitySchema,
      PlaylistEntitySchema,
      ProfileEntitySchema,
      QueueEntitySchema,
    ],
    directory: dir.path,
  );

  final handler = await AudioService.init(
    builder: () => TuneVerseAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ashtroid.tuneverse.audio',
      androidNotificationChannelName: 'TuneVerse',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  return (isar, handler);
}
