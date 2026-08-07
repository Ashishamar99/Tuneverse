import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/core/theme/default_art.dart';
import 'package:tuneverse/data/platform/audio_handler.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  void _confirmClear(
      BuildContext context, TuneVerseAudioHandler handler, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Clear Queue',
            style: TextStyle(color: AppTheme.onDark)),
        content: const Text('Remove all tracks from the queue?',
            style: TextStyle(color: AppTheme.onDarkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              handler.clearQueue();
              ref.read(nowPlayingProvider.notifier).state = null;
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Queue'),
        foregroundColor: AppTheme.onDark,
      ),
      body: StreamBuilder<List<MediaItem>>(
        stream: handler.queue,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Queue is empty',
                style: TextStyle(color: AppTheme.onDarkSecondary),
              ),
            );
          }

          return StreamBuilder<MediaItem?>(
            stream: handler.mediaItem,
            builder: (context, currentSnap) {
              final currentId = currentSnap.data?.id;

              return Column(
                children: [
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: items.length,
                      onReorderItem: (oldIndex, newIndex) {
                        if (oldIndex == newIndex) return;
                        handler.moveQueueItem(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isCurrent = item.id == currentId;

                        return _QueueTile(
                          key: ValueKey('${item.id}_$index'),
                          item: item,
                          index: index,
                          isCurrent: isCurrent,
                          onTap: () => handler.skipToQueueItem(index),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.clear_all_rounded,
                            color: Colors.redAccent),
                        label: const Text('Clear Queue',
                            style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _confirmClear(context, handler, ref),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;

  const _QueueTile({
    super.key,
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: item.artUri != null
              ? CachedNetworkImage(
                  imageUrl: item.artUri.toString(),
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      DefaultArt.image(item.id),
                )
              : DefaultArt.image(item.id),
        ),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent
              ? Theme.of(context).colorScheme.primary
              : AppTheme.onDark,
          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        item.artist ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.onDarkSecondary, fontSize: 13),
      ),
      trailing: isCurrent
          ? Icon(Icons.equalizer_rounded,
              color: Theme.of(context).colorScheme.primary, size: 20)
          : const Icon(Icons.drag_handle_rounded,
              color: AppTheme.onDarkSecondary, size: 20),
      onTap: onTap,
    );
  }

}
