import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/data/sources/youtube/youtube_source.dart';
import 'package:tuneverse/domain/entities/track.dart';

final youtubeSourceProvider = Provider<YouTubeSource>((ref) {
  final source = YouTubeSource();
  ref.onDispose(source.dispose);
  return source;
});

final youtubeSearchProvider =
    FutureProvider.family<List<Track>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final source = ref.watch(youtubeSourceProvider);
  return source.search(query);
});

final nowPlayingProvider = StateProvider<Track?>((ref) => null);

final playTrackProvider = Provider((ref) {
  return (Track track) async {
    final handler = ref.read(audioHandlerProvider);
    final youtube = ref.read(youtubeSourceProvider);

    ref.read(nowPlayingProvider.notifier).state = track;

    final Uri uri;
    if (track.localPath != null && track.isDownloaded) {
      uri = Uri.file(track.localPath!);
    } else {
      uri = await youtube.getStreamUri(track);
    }

    final mediaItem = MediaItem(
      id: track.sourceId,
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
    );

    await handler.playTrack(mediaItem, uri);
    handler.recordPlay(track);
  };
});
