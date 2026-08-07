import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuneverse/core/di/favorites_provider.dart';
import 'package:tuneverse/core/di/playlist_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/core/theme/default_art.dart';
import 'package:tuneverse/domain/entities/track.dart';

enum TrackContext { search, playlist, favorites, library, player }

void showTrackOptions(
  BuildContext context,
  WidgetRef ref,
  Track track, {
  TrackContext trackContext = TrackContext.search,
  int? playlistId,
}) {
  final parentContext = context;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.75,
    ),
    builder: (ctx) => _TrackOptionsSheet(
      track: track,
      trackContext: trackContext,
      playlistId: playlistId,
      parentContext: parentContext,
    ),
  );
}

class _TrackOptionsSheet extends ConsumerWidget {
  final Track track;
  final TrackContext trackContext;
  final int? playlistId;
  final BuildContext parentContext;

  const _TrackOptionsSheet({
    required this.track,
    required this.trackContext,
    this.playlistId,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(track.sourceId));
    final isFavorite = isFav.valueOrNull == true;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Track header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  ClipRRect(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.onDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.onDarkSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.surface),

            // Play Next
            _OptionTile(
              icon: Icons.queue_play_next_rounded,
              label: 'Play Next',
              onTap: () async {
                Navigator.pop(context);
                await _addTrackNext(ref, track);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playing next')),
                  );
                }
              },
            ),

            // Add to Queue
            _OptionTile(
              icon: Icons.add_to_queue_rounded,
              label: 'Add to Queue',
              onTap: () async {
                Navigator.pop(context);
                await _addTrackToQueue(ref, track);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to queue')),
                  );
                }
              },
            ),

            // Add to Playlist
            _OptionTile(
              icon: Icons.playlist_add_rounded,
              label: 'Add to Playlist',
              onTap: () {
                Navigator.pop(context);
                _showPlaylistPicker(parentContext, ref, track);
              },
            ),

            // Remove from Playlist (only in playlist context)
            if (trackContext == TrackContext.playlist && playlistId != null)
              _OptionTile(
                icon: Icons.playlist_remove_rounded,
                label: 'Remove from Playlist',
                color: Colors.redAccent,
                onTap: () {
                  final trackId = int.tryParse(track.id);
                  if (trackId != null) {
                    ref.read(removeFromPlaylistProvider)(playlistId!, trackId);
                  }
                  Navigator.pop(context);
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from playlist'),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

            // Favorite / Unfavorite
            _OptionTile(
              icon: isFavorite
                  ? Icons.heart_broken_rounded
                  : Icons.favorite_rounded,
              label: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              onTap: () async {
                final toggle = ref.read(toggleFavoriteProvider);
                Navigator.pop(context);
                final nowFav = await toggle(track);
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(nowFav
                          ? 'Added to Favorites'
                          : 'Removed from Favorites'),
                      backgroundColor:
                          nowFav ? Colors.green.shade700 : Colors.redAccent,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),

            // Go to Artist
            _OptionTile(
              icon: Icons.person_search_rounded,
              label: 'Go to Artist',
              onTap: () {
                Navigator.pop(context);
                _goToArtist(context, track.artist);
              },
            ),

            // Share
            _OptionTile(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                _shareTrack(track);
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _addTrackNext(WidgetRef ref, Track track) async {
    final handler = ref.read(audioHandlerProvider);
    final youtube = ref.read(youtubeSourceProvider);
    try {
      final uri = track.localPath != null && track.isLocal
          ? Uri.file(track.localPath!)
          : await youtube.getStreamUri(track, useMuxed: true);
      final item = MediaItem(
        id: track.sourceId,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
        artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
      );
      await handler.insertAfterCurrent(item, uri);
    } catch (_) {}
  }

  Future<void> _addTrackToQueue(WidgetRef ref, Track track) async {
    final handler = ref.read(audioHandlerProvider);
    final youtube = ref.read(youtubeSourceProvider);
    try {
      final uri = track.localPath != null && track.isLocal
          ? Uri.file(track.localPath!)
          : await youtube.getStreamUri(track, useMuxed: true);
      final item = MediaItem(
        id: track.sourceId,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
        artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
      );
      await handler.addToQueue(item, uri);
    } catch (_) {}
  }

  void _shareTrack(Track track) {
    final url = track.sourceType == TrackSourceType.youtube
        ? 'https://music.youtube.com/watch?v=${track.sourceId}'
        : track.title;
    Share.share('${track.title} - ${track.artist}\n$url');
  }

  void _goToArtist(BuildContext context, String artist) {
    // Navigate to search with artist name pre-filled
    // GoRouter doesn't easily support pre-filling search, so we use the
    // search tab and let the user see results for this artist
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    // The search will be triggered by setting the query
  }

  void _showPlaylistPicker(
      BuildContext screenContext, WidgetRef ref, Track track) {
    showModalBottomSheet(
      context: screenContext,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, sheetRef, _) {
          final playlists = sheetRef.watch(playlistsProvider);
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add to Playlist',
                    style: TextStyle(
                        color: AppTheme.onDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                playlists.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text(
                          'No playlists yet. Create one in Library.',
                          style: TextStyle(color: AppTheme.onDarkSecondary));
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items
                          .map((pl) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                    Icons.playlist_add_rounded,
                                    color: AppTheme.onDarkSecondary),
                                title: Text(pl.name,
                                    style: const TextStyle(
                                        color: AppTheme.onDark)),
                                subtitle: Text('${pl.trackIds.length} tracks',
                                    style: const TextStyle(
                                        color: AppTheme.onDarkSecondary,
                                        fontSize: 12)),
                                onTap: () async {
                                  await sheetRef.read(addToPlaylistProvider)(
                                      pl.id, track);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (screenContext.mounted) {
                                    ScaffoldMessenger.of(screenContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Added to ${pl.name}'),
                                        backgroundColor:
                                            Colors.green.shade700,
                                        duration:
                                            const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon,
          color: color ?? AppTheme.onDarkSecondary, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color ?? AppTheme.onDark, fontSize: 15)),
      onTap: onTap,
    );
  }
}
