import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/data/sources/resolver/metadata_fetcher.dart';
import 'package:tuneverse/data/sources/resolver/universal_resolver.dart';
import 'package:tuneverse/domain/entities/track.dart';

final spotifyFetcherProvider = Provider<SpotifyFetcher?>((ref) {
  // Returns null until user configures Spotify credentials in Settings.
  // Without credentials, the resolver falls back to YouTube search.
  return null;
});

final universalResolverProvider = Provider<UniversalResolver>((ref) {
  return UniversalResolver(
    youtube: ref.watch(youtubeSourceProvider),
    spotify: ref.watch(spotifyFetcherProvider),
  );
});

final resolveLinkProvider =
    FutureProvider.family<List<Track>, String>((ref, url) async {
  final resolver = ref.watch(universalResolverProvider);
  return resolver.resolve(url);
});
