import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/playlist_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));
    final isar = ref.watch(isarProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<PlaylistEntity?>(
        future: isar.playlistEntitys.get(playlistId),
        builder: (context, playlistSnap) {
          final playlist = playlistSnap.data;
          final name = playlist?.name ?? 'Playlist';

          return CustomScrollView(
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
                  if (playlist != null)
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
                            style:
                                TextStyle(color: AppTheme.onDarkSecondary)),
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
          );
        },
      ),
    );
  }

  Future<void> _playAll(WidgetRef ref, BuildContext context) async {
    final tracks = ref.read(playlistTracksProvider(playlistId)).valueOrNull;
    if (tracks == null || tracks.isEmpty) return;
    await ref.read(playTrackProvider)(tracks.first);
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
