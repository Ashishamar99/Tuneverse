import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/constants/app_constants.dart';
import 'package:tuneverse/core/di/download_providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/data/services/download_manager.dart';
import 'package:tuneverse/domain/entities/track.dart';

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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounceDuration, () {
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  hintText: 'Search songs, artists...',
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
            Expanded(
              child: _query.isEmpty
                  ? const Center(
                      child: Text(
                        'Search for music',
                        style: TextStyle(color: AppTheme.onDarkSecondary),
                      ),
                    )
                  : _SearchResults(query: _query),
            ),
          ],
        ),
      ),
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

class _TrackTile extends ConsumerWidget {
  final Track track;
  const _TrackTile({required this.track});

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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Hero(
        tag: 'album-art-${track.sourceId}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: track.artworkUrl != null
                ? CachedNetworkImage(
                    imageUrl: track.artworkUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.surfaceElevated,
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: AppTheme.onDarkSecondary,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surfaceElevated,
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: AppTheme.onDarkSecondary,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.surfaceElevated,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppTheme.onDarkSecondary,
                    ),
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
          _DownloadButton(track: track),
        ],
      ),
      onTap: () async {
        await ref.read(playTrackProvider)(track);
        final error = ref.read(playbackErrorProvider);
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playback failed: $error'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  final Track track;
  const _DownloadButton({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(isDownloadedProvider(track.sourceId));
    if (downloaded) {
      return const Icon(
        Icons.download_done_rounded,
        color: AppTheme.onDarkSecondary,
        size: 20,
      );
    }

    final progress = ref.watch(downloadProgressProvider).valueOrNull;
    final isThisTrack = progress?.trackId == track.sourceId;

    if (isThisTrack && progress!.status == DownloadStatus.downloading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: progress.progress > 0 ? progress.progress : null,
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return GestureDetector(
      onTap: () => ref.read(startDownloadProvider)(track),
      child: const Icon(
        Icons.download_rounded,
        color: AppTheme.onDarkSecondary,
        size: 20,
      ),
    );
  }
}
