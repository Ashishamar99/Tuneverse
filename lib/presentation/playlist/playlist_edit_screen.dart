import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/playlist_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/core/theme/default_art.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

class PlaylistEditScreen extends ConsumerStatefulWidget {
  final int playlistId;
  const PlaylistEditScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistEditScreen> createState() => _PlaylistEditScreenState();
}

class _PlaylistEditScreenState extends ConsumerState<PlaylistEditScreen> {
  List<_ReorderItem>? _items;
  bool _changed = false;

  Future<void> _loadTracks() async {
    final isar = ref.read(isarProvider);
    final playlist = await isar.playlistEntitys.get(widget.playlistId);
    if (playlist == null || !mounted) return;

    final items = <_ReorderItem>[];
    for (final id in playlist.trackIds) {
      final entity = await isar.trackEntitys.get(id);
      if (entity != null) {
        items.add(_ReorderItem(
          isarId: id,
          track: entity.toDomain(),
        ));
      }
    }
    setState(() => _items = items);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTracks());
  }

  Future<void> _save() async {
    if (_items == null) return;
    final newIds = _items!.map((i) => i.isarId).toList();
    await ref.read(reorderPlaylistProvider)(widget.playlistId, newIds);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.onDark,
        title: const Text('Edit Order'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_changed)
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _items == null
          ? const Center(child: CircularProgressIndicator())
          : _items!.isEmpty
              ? const Center(
                  child: Text('No tracks',
                      style: TextStyle(color: AppTheme.onDarkSecondary)),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items!.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = _items!.removeAt(oldIndex);
                      _items!.insert(newIndex, item);
                      _changed = true;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _items![index];
                    return _ReorderTile(
                      key: ValueKey(item.isarId),
                      track: item.track,
                      index: index,
                    );
                  },
                ),
      ),
    );
  }
}

class _ReorderItem {
  final int isarId;
  final Track track;
  const _ReorderItem({required this.isarId, required this.track});
}

class _ReorderTile extends StatelessWidget {
  final Track track;
  final int index;
  const _ReorderTile({super.key, required this.track, required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          style: const TextStyle(
            color: AppTheme.onDark,
            fontWeight: FontWeight.w500,
          )),
      subtitle: Text(track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppTheme.onDarkSecondary, fontSize: 13)),
      trailing: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle_rounded,
            color: AppTheme.onDarkSecondary),
      ),
    );
  }
}
