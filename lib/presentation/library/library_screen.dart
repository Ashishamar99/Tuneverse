import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:tuneverse/core/di/favorites_provider.dart';
import 'package:tuneverse/core/di/local_providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/domain/entities/track.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Library',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(text: 'Local'),
                  Tab(text: 'Favorites'),
                  Tab(text: 'Playlists'),
                ],
                indicatorSize: TabBarIndicatorSize.label,
                dividerHeight: 0,
                labelColor: AppTheme.onDark,
                unselectedLabelColor: AppTheme.onDarkSecondary,
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _LocalTab(),
                    _FavoritesTab(),
                    _PlaylistsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalTab extends ConsumerWidget {
  const _LocalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(localTracksProvider);

    return tracksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_off_rounded,
                color: AppTheme.onDarkSecondary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not access music files',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: const TextStyle(
                  color: AppTheme.onDarkSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => ref.invalidate(localTracksProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.music_off_rounded,
                  color: AppTheme.onDarkSecondary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No local music found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add audio files to your device to see them here',
                  style: TextStyle(
                    color: AppTheme.onDarkSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(audioPermissionProvider);
            ref.invalidate(localTracksProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: tracks.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Text(
                    '${tracks.length} track${tracks.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.onDarkSecondary,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return _LocalTrackTile(track: tracks[index - 1]);
            },
          ),
        );
      },
    );
  }
}

class _LocalTrackTile extends ConsumerWidget {
  final Track track;
  const _LocalTrackTile({required this.track});

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
    final mediaStoreId = int.tryParse(track.artworkUrl ?? '');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 52,
          height: 52,
          child: mediaStoreId != null
              ? QueryArtworkWidget(
                  id: mediaStoreId,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: _artworkPlaceholder(),
                )
              : _artworkPlaceholder(),
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
      trailing: Text(
        _formatDuration(track.durationMs),
        style: const TextStyle(
          color: AppTheme.onDarkSecondary,
          fontSize: 13,
        ),
      ),
      onTap: () {
        ref.read(playLocalTrackProvider)(track);
      },
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: const Icon(
        Icons.music_note_rounded,
        color: AppTheme.onDarkSecondary,
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);

    return favs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border_rounded,
                    color: AppTheme.onDarkSecondary, size: 48),
                SizedBox(height: 16),
                Text('No favorites yet',
                    style: TextStyle(color: AppTheme.onDarkSecondary)),
                SizedBox(height: 8),
                Text('Tap the heart icon on any track',
                    style: TextStyle(
                        color: AppTheme.onDarkSecondary, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: track.artworkUrl != null &&
                          track.artworkUrl!.startsWith('http')
                      ? Image.network(track.artworkUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppTheme.surfaceElevated,
                          child: const Icon(Icons.music_note_rounded,
                              color: AppTheme.onDarkSecondary),
                        ),
                ),
              ),
              title: Text(track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.onDark, fontWeight: FontWeight.w500)),
              subtitle: Text(track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.onDarkSecondary, fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.favorite_rounded,
                    color: Colors.redAccent, size: 20),
                onPressed: () {
                  ref.read(toggleFavoriteProvider)(track);
                },
              ),
              onTap: () => ref.read(playTrackProvider)(track),
            );
          },
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Coming soon',
        style: TextStyle(
          color: AppTheme.onDarkSecondary,
          fontSize: 15,
        ),
      ),
    );
  }
}
