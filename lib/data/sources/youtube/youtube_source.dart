import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:tuneverse/domain/entities/track.dart';
import 'package:tuneverse/domain/interfaces/track_source.dart';

class YouTubeSource implements TrackSource {
  final yt.YoutubeExplode _client = yt.YoutubeExplode();

  final Map<String, _CachedUri> _streamCache = {};
  static const _cacheDuration = Duration(hours: 5);

  @override
  Future<List<Track>> search(String query, {int limit = 20}) async {
    final searchList = await _client.search.search(query);
    final results = <Track>[];

    for (final video in searchList.take(limit)) {
      results.add(_videoToTrack(video));
    }

    return results;
  }

  @override
  Future<Uri> getStreamUri(Track track, {bool useMuxed = false}) async {
    final cacheKey = useMuxed ? '${track.sourceId}:muxed' : track.sourceId;
    final cached = _streamCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.uri;
    }

    final manifest = await _client.videos.streamsClient.getManifest(
      yt.VideoId(track.sourceId),
    );

    Uri uri;
    if (useMuxed) {
      final muxed = manifest.muxed.sortByBitrate();
      if (muxed.isNotEmpty) {
        uri = muxed.last.url;
      } else {
        final audio = manifest.audioOnly.sortByBitrate();
        if (audio.isEmpty) {
          throw Exception('No streams available for ${track.sourceId}');
        }
        uri = audio.last.url;
      }
    } else {
      final audio = manifest.audioOnly.sortByBitrate();
      if (audio.isNotEmpty) {
        uri = audio.last.url;
      } else {
        final muxed = manifest.muxed.sortByBitrate();
        if (muxed.isEmpty) {
          throw Exception('No streams available for ${track.sourceId}');
        }
        uri = muxed.last.url;
      }
    }

    _streamCache[cacheKey] = _CachedUri(uri);
    return uri;
  }

  @override
  Future<Track?> resolve(String videoId) async {
    try {
      final video = await _client.videos.get(yt.VideoId(videoId));
      return Track(
        id: '',
        title: video.title,
        artist: video.author,
        durationMs: video.duration?.inMilliseconds,
        artworkUrl: video.thumbnails.highResUrl,
        sourceType: TrackSourceType.youtube,
        sourceId: video.id.value,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Track>> searchMusicOnly(String query, {int limit = 10}) async {
    final searchQuery = '$query topic';
    final searchList = await _client.search.search(searchQuery);
    final results = <Track>[];

    for (final video in searchList.take(limit)) {
      if (_isLikelyMusic(video)) {
        results.add(_videoToTrack(video));
      }
    }

    if (results.isEmpty) {
      return search(query, limit: limit);
    }

    return results;
  }

  bool _isLikelyMusic(yt.Video video) {
    final duration = video.duration;
    if (duration == null) return false;
    return duration.inSeconds > 30 && duration.inSeconds < 600;
  }

  Track _videoToTrack(yt.Video video) {
    return Track(
      id: '',
      title: video.title,
      artist: video.author,
      durationMs: video.duration?.inMilliseconds,
      artworkUrl: video.thumbnails.highResUrl,
      sourceType: TrackSourceType.youtube,
      sourceId: video.id.value,
    );
  }

  void dispose() {
    _client.close();
  }
}

class _CachedUri {
  final Uri uri;
  final DateTime _createdAt;

  _CachedUri(this.uri) : _createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(_createdAt) > YouTubeSource._cacheDuration;
}
