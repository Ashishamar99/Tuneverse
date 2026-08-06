import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

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

              return ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: items.length,
                onReorderItem: (oldIndex, newIndex) {
                  handler.skipToQueueItem(newIndex);
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
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
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

  Widget _placeholder() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: const Icon(Icons.music_note_rounded,
          color: AppTheme.onDarkSecondary, size: 20),
    );
  }
}
