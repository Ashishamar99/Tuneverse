import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/cast_providers.dart';
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

final playbackErrorProvider = StateProvider<String?>((ref) => null);

int _playGeneration = 0;

final playTrackProvider = Provider((ref) {
  return (Track track) async {
    final handler = ref.read(audioHandlerProvider);
    final youtube = ref.read(youtubeSourceProvider);
    final castService = ref.read(castServiceProvider);

    final gen = ++_playGeneration;

    ref.read(playbackErrorProvider.notifier).state = null;
    ref.read(nowPlayingProvider.notifier).state = track;

    try {
      final Uri uri;
      if (track.localPath != null && track.isLocal) {
        uri = Uri.file(track.localPath!);
      } else {
        uri = await youtube.getStreamUri(track);
      }

      if (gen != _playGeneration) return;

      if (castService.isCasting) {
        await handler.pause();
        final castUri = (track.localPath != null && track.isLocal)
            ? uri
            : await youtube.getStreamUri(track, useMuxed: true);
        if (gen != _playGeneration) return;
        await castService.loadMedia(
          streamUri: castUri,
          title: track.title,
          artist: track.artist,
          artworkUrl: track.artworkUrl,
          duration: track.duration,
        );
        handler.recordPlay(track);
        return;
      }

      final mediaItem = MediaItem(
        id: track.sourceId,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
        artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
      );

      try {
        await handler.playTrack(mediaItem, uri);
      } catch (playErr) {
        if (gen != _playGeneration) return;
        if (track.localPath == null || !track.isDownloaded) {
          final muxedUri = await youtube.getStreamUri(track, useMuxed: true);
          if (gen != _playGeneration) return;
          await handler.playTrack(mediaItem, muxedUri);
        } else {
          rethrow;
        }
      }
      handler.recordPlay(track);
    } catch (e, st) {
      debugPrint('[TuneVerse] PLAYBACK ERROR: $e\n$st');
      if (gen != _playGeneration) return;
      ref.read(playbackErrorProvider.notifier).state = e.toString();
      ref.read(nowPlayingProvider.notifier).state = null;
    }
  };
});
