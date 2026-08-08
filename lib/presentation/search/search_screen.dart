import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/constants/app_constants.dart';
import 'package:tuneverse/core/di/favorites_provider.dart';
import 'package:tuneverse/core/di/local_providers.dart';
import 'package:tuneverse/core/di/resolver_providers.dart';
import 'package:tuneverse/core/di/search_history_provider.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/core/theme/default_art.dart';
import 'package:tuneverse/domain/entities/track.dart';
import 'package:tuneverse/presentation/shared/widgets/track_options_sheet.dart';

enum _SearchMode { youtube, local }

final _loadingTrackIdProvider = StateProvider<String?>((ref) => null);
final _searchModeProvider = StateProvider((_) => _SearchMode.youtube);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  static bool _isUrl(String query) =>
      query.startsWith('http://') || query.startsWith('https://');

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounceDuration, () {
      final trimmed = value.trim();
      setState(() => _query = trimmed);
      if (trimmed.isNotEmpty) {
        ref.read(searchHistoryProvider.notifier).add(trimmed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(_searchModeProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: AppTheme.onDark),
                decoration: InputDecoration(
                  hintText: mode == _SearchMode.youtube
                      ? 'Search songs, artists...'
                      : 'Search local files...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ModeChip(
                    label: 'YouTube',
                    icon: Icons.play_circle_outline_rounded,
                    selected: mode == _SearchMode.youtube,
                    accent: accent,
                    onTap: () => ref.read(_searchModeProvider.notifier).state =
                        _SearchMode.youtube,
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: 'Local',
                    icon: Icons.folder_rounded,
                    selected: mode == _SearchMode.local,
                    accent: accent,
                    onTap: () => ref.read(_searchModeProvider.notifier).state =
                        _SearchMode.local,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _query.isEmpty
                  ? _RecentSearches(
                      onTap: (q) {
                        _controller.text = q;
                        setState(() => _query = q);
                      },
                    )
                  : _isUrl(_query)
                      ? _LinkResolver(url: _query)
                      : mode == _SearchMode.local
                          ? _LocalSearchResults(query: _query)
                          : _SearchResults(query: _query),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkResolver extends ConsumerWidget {
  final String url;
  const _LinkResolver({required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resolveLinkProvider(url));

    return result.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Resolving link...',
                style: TextStyle(color: AppTheme.onDarkSecondary)),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not resolve link:\n$error',
            style: const TextStyle(color: AppTheme.onDarkSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(
            child: Text('No tracks found for this link',
                style: TextStyle(color: AppTheme.onDarkSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: tracks.length,
          itemBuilder: (context, index) => _TrackTile(track: tracks[index]),
        );
      },
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(youtubeSearchProvider(query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Search failed: $error',
          style: const TextStyle(color: AppTheme.onDarkSecondary),
          textAlign: TextAlign.center,
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(
            child: Text(
              'No results found',
              style: TextStyle(color: AppTheme.onDarkSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: tracks.length,
          itemBuilder: (context, index) => _TrackTile(track: tracks[index]),
        );
      },
    );
  }
}

class _LocalSearchResults extends ConsumerWidget {
  final String query;
  const _LocalSearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(localSearchProvider(query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Search failed: $error',
          style: const TextStyle(color: AppTheme.onDarkSecondary),
          textAlign: TextAlign.center,
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(
            child: Text(
              'No local files found',
              style: TextStyle(color: AppTheme.onDarkSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: tracks.length,
          itemBuilder: (context, index) =>
              _TrackTile(track: tracks[index], isLocal: true),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : AppTheme.onDarkSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: selected ? accent : AppTheme.onDarkSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? accent : AppTheme.onDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearches extends ConsumerWidget {
  final void Function(String) onTap;
  const _RecentSearches({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);

    if (history.isEmpty) {
      return const Center(
        child: Text(
          'Search for music',
          style: TextStyle(color: AppTheme.onDarkSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Row(
            children: [
              const Text('Recent',
                  style: TextStyle(
                      color: AppTheme.onDarkSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clear(),
                child: const Text('Clear all', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        ...history.map((q) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded,
                  color: AppTheme.onDarkSecondary, size: 20),
              title: Text(q,
                  style: const TextStyle(color: AppTheme.onDark, fontSize: 15)),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.onDarkSecondary, size: 18),
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).remove(q),
              ),
              onTap: () => onTap(q),
            )),
      ],
    );
  }
}

class _TrackTile extends ConsumerWidget {
  final Track track;
  final bool isLocal;
  const _TrackTile({required this.track, this.isLocal = false});

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final isPlaying = nowPlaying?.sourceId == track.sourceId;
    final loadingId = ref.watch(_loadingTrackIdProvider);
    final isLoading = loadingId == track.sourceId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Hero(
        tag: 'album-art-${track.sourceId}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              children: [
                Positioned.fill(
                  child: track.artworkUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.artworkUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              DefaultArt.image(track.sourceId),
                          errorWidget: (_, __, ___) =>
                              DefaultArt.image(track.sourceId),
                        )
                      : DefaultArt.image(track.sourceId),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying
              ? Theme.of(context).colorScheme.primary
              : AppTheme.onDark,
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.onDarkSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.durationMs),
            style: const TextStyle(
              color: AppTheme.onDarkSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          _FavoriteButton(track: track),
          GestureDetector(
            onTap: () => showTrackOptions(context, ref, track),
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.more_vert_rounded,
                  color: AppTheme.onDarkSecondary, size: 20),
            ),
          ),
        ],
      ),
      onTap: () async {
        ref.read(_loadingTrackIdProvider.notifier).state = track.sourceId;
        if (isLocal) {
          await ref.read(playLocalTrackProvider)(track);
        } else {
          await ref.read(playTrackProvider)(track);
        }
        if (context.mounted) {
          ref.read(_loadingTrackIdProvider.notifier).state = null;
        }
        if (!isLocal) {
          final error = ref.read(playbackErrorProvider);
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playback failed: $error'),
                backgroundColor: Colors.red.shade800,
              ),
            );
          }
        }
      },
      onLongPress: () => showTrackOptions(context, ref, track),
    );
  }
}


class _FavoriteButton extends ConsumerWidget {
  final Track track;
  const _FavoriteButton({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(track.sourceId));

    return GestureDetector(
      onTap: () async {
        final nowFav = await ref.read(toggleFavoriteProvider)(track);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nowFav ? 'Added to favorites' : 'Removed from favorites'),
              backgroundColor: nowFav ? Colors.green.shade700 : Colors.red.shade700,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Icon(
        isFav.valueOrNull == true
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        color: isFav.valueOrNull == true
            ? Colors.redAccent
            : AppTheme.onDarkSecondary,
        size: 20,
      ),
    );
  }
}
