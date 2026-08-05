import 'package:tuneverse/data/sources/resolver/link_parser.dart';
import 'package:tuneverse/data/sources/resolver/metadata_fetcher.dart';
import 'package:tuneverse/data/sources/youtube/youtube_source.dart';
import 'package:tuneverse/domain/entities/track.dart';

class UniversalResolver {
  final YouTubeSource _youtube;
  final SpotifyFetcher? _spotify;
  final AmazonFetcher _amazon = AmazonFetcher();

  UniversalResolver({
    required YouTubeSource youtube,
    SpotifyFetcher? spotify,
  })  : _youtube = youtube,
        _spotify = spotify;

  Future<List<Track>> resolve(String url) async {
    final parsed = LinkParser.parse(url);
    if (parsed == null) {
      return _youtube.search(url);
    }

    switch (parsed.platform) {
      case MusicPlatform.youtube:
      case MusicPlatform.youtubeMusic:
        return _resolveYouTube(parsed);
      case MusicPlatform.spotify:
        return _resolveSpotify(parsed);
      case MusicPlatform.amazonMusic:
        return _resolveAmazon(parsed);
      case MusicPlatform.unknown:
        return _youtube.search(url);
    }
  }

  Future<List<Track>> _resolveYouTube(ParsedLink link) async {
    if (link.type == LinkType.track) {
      final track = await _youtube.resolve(link.id);
      return track != null ? [track] : [];
    }
    return [];
  }

  Future<List<Track>> _resolveSpotify(ParsedLink link) async {
    if (_spotify == null) {
      return _youtube.search('${link.id} spotify');
    }

    switch (link.type) {
      case LinkType.track:
        final metadata = await _spotify.fetchTrack(link.id);
        if (metadata == null) return [];
        return _findOnYouTube(metadata);

      case LinkType.playlist:
        final tracks = await _spotify.fetchPlaylist(link.id);
        final results = <Track>[];
        for (final meta in tracks) {
          final found = await _findOnYouTube(meta);
          if (found.isNotEmpty) results.add(found.first);
        }
        return results;

      default:
        return [];
    }
  }

  Future<List<Track>> _resolveAmazon(ParsedLink link) async {
    final metadata = await _amazon.fetchFromUrl(link.originalUrl);
    if (metadata == null) return [];
    return _findOnYouTube(metadata);
  }

  Future<List<Track>> _findOnYouTube(TrackMetadata metadata) async {
    final query = '${metadata.title} ${metadata.artist}';
    final results = await _youtube.searchMusicOnly(query, limit: 5);

    if (results.isEmpty) return [];

    final best = _pickBestMatch(results, metadata);
    return [best];
  }

  Track _pickBestMatch(List<Track> candidates, TrackMetadata target) {
    if (candidates.length == 1) return candidates.first;

    double bestScore = -1;
    Track bestTrack = candidates.first;

    for (final candidate in candidates) {
      double score = 0;

      score += _titleSimilarity(candidate.title, target.title) * 3;
      score += _titleSimilarity(candidate.artist, target.artist) * 2;

      if (target.durationMs != null && candidate.durationMs != null) {
        final diff = (candidate.durationMs! - target.durationMs!).abs();
        if (diff < 3000) {
          score += 3;
        } else if (diff < 10000) {
          score += 1;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestTrack = candidate;
      }
    }

    return bestTrack;
  }

  double _titleSimilarity(String a, String b) {
    final aNorm = a.toLowerCase().trim();
    final bNorm = b.toLowerCase().trim();

    if (aNorm == bNorm) return 1.0;
    if (aNorm.contains(bNorm) || bNorm.contains(aNorm)) return 0.8;

    final aWords = aNorm.split(RegExp(r'\s+'));
    final bWords = bNorm.split(RegExp(r'\s+'));
    final matches = aWords.where((w) => bWords.contains(w)).length;
    final total = aWords.length + bWords.length;

    return total > 0 ? (2 * matches) / total : 0;
  }
}
