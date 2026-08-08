import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuneverse/core/di/playlist_providers.dart';
import 'package:tuneverse/core/di/profile_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/core/theme/default_art.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';
import 'package:tuneverse/presentation/shared/widgets/mini_player.dart';
import 'package:tuneverse/presentation/shared/widgets/track_options_sheet.dart';

final _playlistEntityProvider =
    FutureProvider.family<PlaylistEntity?, int>((ref, playlistId) async {
  final isar = ref.watch(isarProvider);
  return isar.playlistEntitys.get(playlistId);
});

enum PlaylistSortField { added, az }

class PlaylistSort {
  final PlaylistSortField field;
  final bool ascending;
  const PlaylistSort({this.field = PlaylistSortField.added, this.ascending = true});

  PlaylistSort toggleDirection() => PlaylistSort(field: field, ascending: !ascending);
  PlaylistSort withField(PlaylistSortField f) => PlaylistSort(field: f, ascending: ascending);
}

final _playlistSortProvider =
    StateProvider.family<PlaylistSort, int>((ref, _) => const PlaylistSort());

class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  List<Track> _sorted(List<Track> tracks, PlaylistSort sort) {
    final list = [...tracks];
    switch (sort.field) {
      case PlaylistSortField.az:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case PlaylistSortField.added:
        break;
    }
    if (!sort.ascending) list.reversed;
    return sort.ascending ? list : list.reversed.toList();
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, PlaylistEntity pl) {
    final controller = TextEditingController(text: pl.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Rename Playlist',
            style: TextStyle(color: AppTheme.onDark)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.onDark),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(renamePlaylistProvider)(pl.id, name);
                ref.invalidate(_playlistEntityProvider(pl.id));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));
    final entityAsync = ref.watch(_playlistEntityProvider(playlistId));
    final entity = entityAsync.valueOrNull;
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final lastPlayedMap = ref.watch(lastPlayedInPlaylistProvider);
    final lastPlayedSourceId = lastPlayedMap[playlistId];
    final sort = ref.watch(_playlistSortProvider(playlistId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const SafeArea(child: MiniPlayer()),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            foregroundColor: AppTheme.onDark,
            pinned: true,
            title: Text(entity?.name ?? 'Playlist',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            actions: [
              if (entity != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.onDarkSecondary),
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _showRenameDialog(context, ref, entity);
                      case 'edit_order':
                        context.push('/playlist/$playlistId/edit');
                      case 'delete':
                        ref.read(deletePlaylistProvider)(playlistId);
                        context.pop();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              color: AppTheme.onDarkSecondary, size: 20),
                          SizedBox(width: 12),
                          Text('Rename',
                              style: TextStyle(color: AppTheme.onDark)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit_order',
                      child: Row(
                        children: [
                          Icon(Icons.reorder_rounded,
                              color: AppTheme.onDarkSecondary, size: 20),
                          SizedBox(width: 12),
                          Text('Edit Order',
                              style: TextStyle(color: AppTheme.onDark)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          tracksAsync.when(
            loading: () =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (tracks) => SliverToBoxAdapter(
              child: _PlaylistHeader(
                entity: entity,
                tracks: tracks,
                profileName: profile?.name,
                currentSort: sort,
                onSortChanged: (s) => ref
                    .read(_playlistSortProvider(playlistId).notifier)
                    .state = s,
                onToggleDirection: () => ref
                    .read(_playlistSortProvider(playlistId).notifier)
                    .state = sort.toggleDirection(),
                onPlay: tracks.isEmpty
                    ? null
                    : () => _playFrom(ref, context, tracks,
                        lastPlayedSourceId: lastPlayedSourceId),
                onShuffle: tracks.isEmpty
                    ? null
                    : () =>
                        _playFrom(ref, context, tracks, shuffle: true),
              ),
            ),
          ),
          tracksAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (rawTracks) {
              final tracks = _sorted(rawTracks, sort);
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
                      onTap: () {
                        ref
                            .read(
                                lastPlayedInPlaylistProvider.notifier)
                            .update((state) =>
                                {...state, playlistId: track.sourceId});
                        ref.read(playTrackProvider)(track);
                      },
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

  Future<void> _playFrom(
    WidgetRef ref,
    BuildContext context,
    List<Track> tracks, {
    String? lastPlayedSourceId,
    bool shuffle = false,
  }) async {
    if (tracks.isEmpty) return;

    final handler = ref.read(audioHandlerProvider);
    final youtube = ref.read(youtubeSourceProvider);

    final orderedTracks = [...tracks];
    if (shuffle) orderedTracks.shuffle();

    ref.read(nowPlayingProvider.notifier).state = orderedTracks.first;

    final items = <(MediaItem, Uri)>[];
    for (final track in orderedTracks) {
      try {
        final uri = track.localPath != null && track.isLocal
            ? Uri.file(track.localPath!)
            : await youtube.getStreamUri(track, useMuxed: true);
        final mediaItem = MediaItem(
          id: track.sourceId,
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          artUri: track.artworkUrl != null
              ? Uri.parse(track.artworkUrl!)
              : null,
        );
        items.add((mediaItem, uri));
      } catch (_) {}
    }

    if (items.isEmpty) return;

    int startIndex = 0;
    if (!shuffle && lastPlayedSourceId != null) {
      final idx =
          items.indexWhere((item) => item.$1.id == lastPlayedSourceId);
      if (idx >= 0) startIndex = idx;
    }

    await handler.loadQueue(items);
    if (startIndex > 0) {
      await handler.skipToQueueItem(startIndex);
    }
    await handler.play();
  }
}

class _PlaylistHeader extends StatelessWidget {
  final PlaylistEntity? entity;
  final List<Track> tracks;
  final String? profileName;
  final PlaylistSort currentSort;
  final ValueChanged<PlaylistSort> onSortChanged;
  final VoidCallback onToggleDirection;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;

  const _PlaylistHeader({
    required this.entity,
    required this.tracks,
    this.profileName,
    required this.currentSort,
    required this.onSortChanged,
    required this.onToggleDirection,
    this.onPlay,
    this.onShuffle,
  });

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final artUrl = tracks.isNotEmpty ? tracks.first.artworkUrl : null;
    final placeholderId =
        tracks.isNotEmpty ? tracks.first.sourceId : (entity?.name ?? 'pl');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: artUrl != null && artUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: artUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              DefaultArt.image(placeholderId),
                        )
                      : DefaultArt.image(placeholderId),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      entity?.name ?? 'Playlist',
                      style: const TextStyle(
                        color: AppTheme.onDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${tracks.length} track${tracks.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppTheme.onDarkSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (entity != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${profileName ?? 'You'} · ${_formatDate(entity!.createdAt)}',
                        style: const TextStyle(
                          color: AppTheme.onDarkSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (onPlay != null || onShuffle != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded,
                        size: 20),
                    label: const Text('Play'),
                    onPressed: onPlay,
                    style: FilledButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon:
                        const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text('Shuffle'),
                    onPressed: onShuffle,
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (tracks.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _SortChip(
                  label: 'Date Added',
                  selected: currentSort.field == PlaylistSortField.added,
                  onTap: () => onSortChanged(currentSort.withField(PlaylistSortField.added)),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'A–Z',
                  selected: currentSort.field == PlaylistSortField.az,
                  onTap: () => onSortChanged(currentSort.withField(PlaylistSortField.az)),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: currentSort.ascending ? '↑' : '↓',
                  selected: true,
                  onTap: onToggleDirection,
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${track.title}"'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
            ),
          );
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
                    errorWidget: (_, __, ___) =>
                        DefaultArt.image(track.sourceId),
                  )
                : DefaultArt.image(track.sourceId),
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
        trailing: GestureDetector(
          onTap: () => showTrackOptions(context, ref, track,
              trackContext: TrackContext.playlist,
              playlistId: playlistId),
          child: const Icon(Icons.more_vert_rounded,
              color: AppTheme.onDarkSecondary, size: 20),
        ),
        onTap: onTap,
        onLongPress: () => showTrackOptions(context, ref, track,
            trackContext: TrackContext.playlist, playlistId: playlistId),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.2) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: selected ? Border.all(color: accent, width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : AppTheme.onDarkSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
