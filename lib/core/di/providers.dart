import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/models/profile_entity.dart';
import 'package:tuneverse/data/models/queue_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/data/platform/audio_handler.dart';
import 'package:tuneverse/data/sources/youtube/youtube_source.dart';
import 'package:tuneverse/domain/entities/track.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be overridden at app startup');
});

final audioHandlerProvider = Provider<TuneVerseAudioHandler>((ref) {
  throw UnimplementedError('AudioHandler must be overridden at app startup');
});

final audioPlayerProvider = Provider((ref) {
  return ref.watch(audioHandlerProvider).player;
});

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
    builder: () => TuneVerseAudioHandler(isar),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ashtroid.tuneverse.audio',
      androidNotificationChannelName: 'TuneVerse',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final autoYouTube = YouTubeSource();
  handler.setYouTubeResolver((sourceId, {bool useMuxed = false}) async {
    final track = Track(
      id: '',
      title: '',
      artist: '',
      sourceType: TrackSourceType.youtube,
      sourceId: sourceId,
    );
    return autoYouTube.getStreamUri(track, useMuxed: useMuxed);
  });

  session.becomingNoisyEventStream.listen((_) {
    handler.pause();
  });

  session.interruptionEventStream.listen((event) {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          handler.player.setVolume(0.5);
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          handler.pause();
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          handler.player.setVolume(1.0);
        case AudioInterruptionType.pause:
          handler.play();
        case AudioInterruptionType.unknown:
          break;
      }
    }
  });

  return (isar, handler);
}
