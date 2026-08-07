import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/playlist_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

final _playlistNameProvider =
    FutureProvider.family<String, int>((ref, playlistId) async {
  final isar = ref.watch(isarProvider);
  final playlist = await isar.playlistEntitys.get(playlistId);
  return playlist?.name ?? 'Playlist';
});

class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));
    final nameAsync = ref.watch(_playlistNameProvider(playlistId));
    final name = nameAsync.valueOrNull ?? 'Playlist';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            foregroundColor: AppTheme.onDark,
            pinned: true,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.play_circle_filled_rounded),
                iconSize: 36,
                onPressed: () => _playAll(ref, context),
              ),
            ],
          ),
          tracksAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (tracks) {
              if (tracks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No tracks in this playlist',
                        style: TextStyle(color: AppTheme.onDarkSecondary)),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final track = tracks[index];
                    return _PlaylistTrackTile(
                      track: track,
                      playlistId: playlistId,
                      onTap: () => ref.read(playTrackProvider)(track),
                    );
                  },
                  childCount: tracks.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _playAll(WidgetRef ref, BuildContext context) async {
    final tracks = ref.read(playlistTracksProvider(playlistId)).valueOrNull;
    if (tracks == null || tracks.isEmpty) return;

    final handler = ref.read(audioHandlerProvider);
    final youtube = ref.read(youtubeSourceProvider);

    ref.read(nowPlayingProvider.notifier).state = tracks.first;

    final items = <(MediaItem, Uri)>[];
    for (final track in tracks) {
      try {
        final uri = track.localPath != null && track.isDownloaded
            ? Uri.file(track.localPath!)
            : await youtube.getStreamUri(track, useMuxed: true);
        final mediaItem = MediaItem(
          id: track.sourceId,
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          artUri:
              track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
        );
        items.add((mediaItem, uri));
      } catch (_) {
        // Skip tracks that fail to resolve
      }
    }

    if (items.isEmpty) return;
    await handler.loadQueue(items);
    await handler.play();
  }
}

class _PlaylistTrackTile extends ConsumerWidget {
  final Track track;
  final int playlistId;
  final VoidCallback onTap;

  const _PlaylistTrackTile({
    required this.track,
    required this.playlistId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final isCurrent = nowPlaying?.sourceId == track.sourceId;

    return Dismissible(
      key: ValueKey('${track.sourceId}_$playlistId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        final trackId = int.tryParse(track.id);
        if (trackId != null) {
          ref.read(removeFromPlaylistProvider)(playlistId, trackId);
        }
      },
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: track.artworkUrl != null &&
                    track.artworkUrl!.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: track.artworkUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        title: Text(track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.onDark,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            )),
        subtitle: Text(track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppTheme.onDarkSecondary, fontSize: 13)),
        onTap: onTap,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: const Icon(Icons.music_note_rounded,
          color: AppTheme.onDarkSecondary, size: 20),
    );
  }
}
