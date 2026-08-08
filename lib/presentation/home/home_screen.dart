import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/router/app_router.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/core/theme/default_art.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';
import 'package:tuneverse/presentation/shared/widgets/cast_button.dart';

final _recentlyPlayedProvider = FutureProvider<List<Track>>((ref) async {
  ref.watch(nowPlayingProvider);
  final isar = ref.watch(isarProvider);
  final entities = await isar.trackEntitys
      .filter()
      .lastPlayedAtIsNotNull()
      .sortByLastPlayedAtDesc()
      .limit(5)
      .findAll();
  return entities.map((e) => e.toDomain()).toList();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'TuneVerse',
                          style: TextStyle(
                            color: AppTheme.onDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const CastButton(),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          color: AppTheme.onDarkSecondary,
                          onPressed: () => context.push(AppRoutes.settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _greeting(),
                      style: const TextStyle(
                        color: AppTheme.onDarkSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: AppTheme.onDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () => context.go(AppRoutes.search),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.link_rounded,
                      label: 'Paste Link',
                      onTap: () => _showPasteLinkDialog(context, ref),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.library_music_rounded,
                      label: 'Library',
                      onTap: () => context.go(AppRoutes.library),
                    ),
                  ],
                ),
              ),
            ),

            if (nowPlaying != null) ...[
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Now Playing',
                    style: TextStyle(
                      color: AppTheme.onDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.player),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_filled_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 48,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nowPlaying.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.onDark,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nowPlaying.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.onDarkSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            _RecentlyPlayedSection(playTrack: ref.read(playTrackProvider)),

            if (nowPlaying == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        color: AppTheme.onDarkSecondary,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Search for music or paste a link',
                        style: TextStyle(
                          color: AppTheme.onDarkSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showPasteLinkDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste a music link',
                style: TextStyle(
                  color: AppTheme.onDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Spotify, Amazon Music, YouTube, or YouTube Music',
                style: TextStyle(
                  color: AppTheme.onDarkSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppTheme.onDark),
                decoration: const InputDecoration(
                  hintText: 'https://open.spotify.com/track/...',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final url = controller.text.trim();
                    if (url.isNotEmpty) {
                      Navigator.pop(context);
                      context.push(
                        '${AppRoutes.resolve}?url=${Uri.encodeComponent(url)}',
                      );
                    }
                  },
                  child: const Text('Play'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentlyPlayedSection extends ConsumerWidget {
  final Future<void> Function(Track) playTrack;
  const _RecentlyPlayedSection({required this.playTrack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(_recentlyPlayedProvider);
    final tracks = recentAsync.valueOrNull;
    if (tracks == null || tracks.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Recently Played',
              style: TextStyle(
                color: AppTheme.onDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = tracks[index];
                final nowPlaying = ref.watch(nowPlayingProvider);
                final isCurrent = nowPlaying?.sourceId == track.sourceId;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
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
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : AppTheme.onDark,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.onDarkSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => playTrack(track),
                );
              },
              childCount: tracks.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusStandard),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.onDark, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.onDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
