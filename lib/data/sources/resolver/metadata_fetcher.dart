import 'dart:convert';
import 'package:dio/dio.dart';

class TrackMetadata {
  final String title;
  final String artist;
  final int? durationMs;
  final String? artworkUrl;

  const TrackMetadata({
    required this.title,
    required this.artist,
    this.durationMs,
    this.artworkUrl,
  });
}

class SpotifyFetcher {
  final Dio _dio = Dio();
  String? _accessToken;
  DateTime? _tokenExpiry;

  final String clientId;
  final String clientSecret;

  SpotifyFetcher({required this.clientId, required this.clientSecret});

  Future<void> _ensureToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final credentials = base64Encode(
      utf8.encode('$clientId:$clientSecret'),
    );

    final response = await _dio.post(
      'https://accounts.spotify.com/api/token',
      data: 'grant_type=client_credentials',
      options: Options(
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );

    _accessToken = response.data['access_token'];
    final expiresIn = response.data['expires_in'] as int;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
  }

  Future<TrackMetadata?> fetchTrack(String trackId) async {
    try {
      await _ensureToken();
      final response = await _dio.get(
        'https://api.spotify.com/v1/tracks/$trackId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      final data = response.data;
      final artists = (data['artists'] as List)
          .map((a) => a['name'] as String)
          .join(', ');
      final images = data['album']?['images'] as List?;
      final artwork = images?.isNotEmpty == true ? images!.first['url'] : null;

      return TrackMetadata(
        title: data['name'],
        artist: artists,
        durationMs: data['duration_ms'],
        artworkUrl: artwork,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<TrackMetadata>> fetchPlaylist(String playlistId) async {
    try {
      await _ensureToken();
      final response = await _dio.get(
        'https://api.spotify.com/v1/playlists/$playlistId/tracks',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      final items = response.data['items'] as List;
      return items
          .where((item) => item['track'] != null)
          .map((item) {
            final track = item['track'];
            final artists = (track['artists'] as List)
                .map((a) => a['name'] as String)
                .join(', ');
            return TrackMetadata(
              title: track['name'],
              artist: artists,
              durationMs: track['duration_ms'],
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class AmazonFetcher {
  final Dio _dio = Dio();

  Future<TrackMetadata?> fetchFromUrl(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/120.0.0.0 Mobile Safari/537.36',
          },
          followRedirects: true,
        ),
      );

      final html = response.data as String;

      final titleMatch = RegExp(
        r'<meta\s+property="og:title"\s+content="([^"]+)"',
      ).firstMatch(html);
      final descMatch = RegExp(
        r'<meta\s+property="og:description"\s+content="([^"]+)"',
      ).firstMatch(html);

      if (titleMatch == null) return null;

      final rawTitle = _decodeHtmlEntities(titleMatch.group(1)!);
      final rawDesc = descMatch != null
          ? _decodeHtmlEntities(descMatch.group(1)!)
          : '';

      final parts = rawTitle.split(' - ');
      final title = parts.isNotEmpty ? parts.first.trim() : rawTitle;
      final artist = parts.length > 1 ? parts[1].trim() : rawDesc;

      return TrackMetadata(title: title, artist: artist);
    } catch (_) {
      return null;
    }
  }

  Future<List<TrackMetadata>> fetchPlaylistTracks(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/120.0.0.0 Mobile Safari/537.36',
          },
          followRedirects: true,
        ),
      );

      final html = response.data as String;
      final titlePattern = RegExp(
        r'<meta\s+property="music:song"\s+content="([^"]+)"',
      );
      final matches = titlePattern.allMatches(html);

      if (matches.isEmpty) {
        final single = await fetchFromUrl(url);
        return single != null ? [single] : [];
      }

      final tracks = <TrackMetadata>[];
      for (final match in matches) {
        final trackUrl = _decodeHtmlEntities(match.group(1)!);
        final meta = await fetchFromUrl(trackUrl);
        if (meta != null) tracks.add(meta);
      }
      return tracks;
    } catch (_) {
      return [];
    }
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}
