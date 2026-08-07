import 'dart:convert';
import 'dart:io';

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

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final videos = await _client.playlists.getVideos(playlistId).toList();
      if (videos.isNotEmpty) {
        return videos.map(_videoToTrack).toList();
      }
    } catch (_) {}
    // youtube_explode_dart getVideos() is broken — fall back to RSS feed
    return _getPlaylistTracksFromRss(playlistId);
  }

  Future<List<Track>> _getPlaylistTracksFromRss(String playlistId) async {
    final url = Uri.parse(
      'https://www.youtube.com/feeds/videos.xml?playlist_id=$playlistId',
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception(
          'Could not fetch playlist (HTTP ${response.statusCode})',
        );
      }
      final body = await response.transform(utf8.decoder).join();
      return _parseRssFeed(body);
    } finally {
      client.close();
    }
  }

  static final _entryPattern = RegExp(r'<entry>(.*?)</entry>', dotAll: true);
  static final _videoIdPattern = RegExp(r'<yt:videoId>(.*?)</yt:videoId>');
  static final _mediaTitlePattern =
      RegExp(r'<media:title>(.*?)</media:title>', dotAll: true);
  static final _titlePattern = RegExp(r'<title>(.*?)</title>');
  static final _authorPattern =
      RegExp(r'<author>.*?<name>(.*?)</name>.*?</author>', dotAll: true);
  static final _thumbnailPattern =
      RegExp(r'<media:thumbnail[^>]*url="([^"]*)"');

  List<Track> _parseRssFeed(String xml) {
    final tracks = <Track>[];
    for (final match in _entryPattern.allMatches(xml)) {
      final entry = match.group(1)!;
      final videoId = _videoIdPattern.firstMatch(entry)?.group(1);
      if (videoId == null) continue;

      final title = _mediaTitlePattern.firstMatch(entry)?.group(1) ??
          _titlePattern.firstMatch(entry)?.group(1) ??
          'Unknown';
      final author =
          _authorPattern.firstMatch(entry)?.group(1) ?? 'Unknown';
      final thumbnail = _thumbnailPattern.firstMatch(entry)?.group(1);

      tracks.add(Track(
        id: '',
        title: _decodeHtmlEntities(title),
        artist: _decodeHtmlEntities(author),
        durationMs: null,
        artworkUrl: thumbnail,
        sourceType: TrackSourceType.youtube,
        sourceId: videoId,
      ));
    }
    if (tracks.isEmpty) {
      throw Exception(
        'Playlist is empty, private, or does not exist.',
      );
    }
    return tracks;
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  Future<String> getPlaylistTitle(String playlistId) async {
    final playlist = await _client.playlists.get(playlistId);
    return playlist.title;
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
