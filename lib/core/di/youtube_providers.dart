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

final playTrackProvider = Provider((ref) {
  return (Track track) async {
    final handler = ref.read(audioHandlerProvider);
    final youtube = ref.read(youtubeSourceProvider);
    final castService = ref.read(castServiceProvider);

    ref.read(playbackErrorProvider.notifier).state = null;
    ref.read(nowPlayingProvider.notifier).state = track;

    try {
      final Uri uri;
      if (track.localPath != null && track.isLocal) {
        uri = Uri.file(track.localPath!);
        debugPrint('[TuneVerse] Playing local file: ${track.localPath}');
      } else {
        debugPrint('[TuneVerse] Fetching stream for: ${track.title} (${track.sourceId})');
        uri = await youtube.getStreamUri(track);
        debugPrint('[TuneVerse] Got audio-only stream URI: $uri');
      }

      // Cast path: send media to Chromecast instead of local player
      if (castService.isCasting) {
        debugPrint('[TuneVerse] Casting to ${castService.connectedDeviceName}');
        await handler.pause();
        await castService.loadMedia(
          streamUri: uri,
          title: track.title,
          artist: track.artist,
          artworkUrl: track.artworkUrl,
          duration: track.duration,
        );
        handler.recordPlay(track);
        debugPrint('[TuneVerse] Cast playback started');
        return;
      }

      final mediaItem = MediaItem(
        id: track.sourceId,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
        artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
      );

      debugPrint('[TuneVerse] Setting audio source and playing...');
      try {
        await handler.playTrack(mediaItem, uri);
      } catch (playErr) {
        if (track.localPath == null || !track.isDownloaded) {
          debugPrint('[TuneVerse] Audio-only failed ($playErr), retrying with muxed stream...');
          final muxedUri = await youtube.getStreamUri(track, useMuxed: true);
          debugPrint('[TuneVerse] Got muxed stream URI: $muxedUri');
          await handler.playTrack(mediaItem, muxedUri);
        } else {
          rethrow;
        }
      }
      handler.recordPlay(track);
      debugPrint('[TuneVerse] Playback started successfully');
    } catch (e, st) {
      debugPrint('[TuneVerse] PLAYBACK ERROR: $e');
      debugPrint('[TuneVerse] Stack trace: $st');
      ref.read(playbackErrorProvider.notifier).state = e.toString();
      ref.read(nowPlayingProvider.notifier).state = null;
    }
  };
});
