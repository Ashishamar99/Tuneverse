import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuneverse/core/di/import_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class ImportPlaylistScreen extends ConsumerStatefulWidget {
  const ImportPlaylistScreen({super.key});

  @override
  ConsumerState<ImportPlaylistScreen> createState() =>
      _ImportPlaylistScreenState();
}

class _ImportPlaylistScreenState extends ConsumerState<ImportPlaylistScreen> {
  final _nameController = TextEditingController(text: 'Imported Playlist');
  final _tracksController = TextEditingController();
  bool _parsed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tracksController.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _tracksController.text.trim();
    if (text.isEmpty) return;

    ref.read(importNotifierProvider.notifier).parseInput(
          text,
          playlistName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        );
    setState(() => _parsed = true);
  }

  void _startMatching() {
    ref.read(importNotifierProvider.notifier).startMatching();
  }

  Future<void> _savePlaylist() async {
    final id =
        await ref.read(importNotifierProvider.notifier).createPlaylist();
    if (id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist created!')),
      );
      ref.read(importNotifierProvider.notifier).reset();
      context.pop();
    }
  }

  void _reset() {
    ref.read(importNotifierProvider.notifier).reset();
    setState(() => _parsed = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.onDark,
        title: const Text('Import Playlist'),
        actions: [
          if (_parsed)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: state.isRunning ? null : _reset,
              tooltip: 'Start over',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _parsed ? _buildMatchView(state) : _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste your tracks',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.onDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'One track per line. Use "Artist - Title" format for best results.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onDarkSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppTheme.onDark),
            decoration: InputDecoration(
              labelText: 'Playlist name',
              labelStyle: const TextStyle(color: AppTheme.onDarkSecondary),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tracksController,
            style: const TextStyle(color: AppTheme.onDark, fontSize: 13),
            maxLines: 15,
            decoration: InputDecoration(
              hintText:
                  'Arijit Singh - Tum Hi Ho\nAP Dhillon - Brown Munde\nDua Lipa - Levitating\n...',
              hintStyle: TextStyle(
                  color: AppTheme.onDarkSecondary.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: Copy your playlist from Amazon Music, Spotify, or any music app and paste here.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.onDarkSecondary.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  _tracksController.text.trim().isEmpty ? null : _parse,
              icon: const Icon(Icons.search_rounded),
              label: Text(
                'Find on YouTube',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.fallbackAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.fallbackAccent.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchView(ImportState state) {
    return Column(
      children: [
        _buildProgressHeader(state),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.tracks.length,
            itemBuilder: (context, index) =>
                _buildTrackTile(state.tracks[index], index),
          ),
        ),
        _buildBottomBar(state),
      ],
    );
  }

  Widget _buildProgressHeader(ImportState state) {
    final total = state.tracks.length;
    final done = state.matched + state.notFound;
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceElevated, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatChip(
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                label: '${state.matched} matched',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.error_rounded,
                color: Colors.orange,
                label: '${state.notFound} not found',
              ),
              const Spacer(),
              Text(
                '$done / $total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.onDarkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.isRunning ? null : progress,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.fallbackAccent),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(ImportTrack track, int index) {
    final IconData icon;
    final Color iconColor;

    switch (track.status) {
      case ImportTrackStatus.pending:
        icon = Icons.hourglass_empty_rounded;
        iconColor = AppTheme.onDarkSecondary;
      case ImportTrackStatus.matching:
        icon = Icons.search_rounded;
        iconColor = AppTheme.fallbackAccent;
      case ImportTrackStatus.matched:
        icon = Icons.check_circle_rounded;
        iconColor = Colors.green;
      case ImportTrackStatus.notFound:
        icon = Icons.error_rounded;
        iconColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          track.title,
          style: TextStyle(
            color: track.status == ImportTrackStatus.notFound
                ? AppTheme.onDarkSecondary
                : AppTheme.onDark,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: track.artist.isNotEmpty
            ? Text(
                track.status == ImportTrackStatus.matched &&
                        track.matchedTrack != null
                    ? '${track.matchedTrack!.artist} (YouTube)'
                    : track.artist,
                style: const TextStyle(
                    color: AppTheme.onDarkSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: track.status == ImportTrackStatus.matching
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }

  Widget _buildBottomBar(ImportState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.surfaceElevated, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!state.isRunning && state.pending > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startMatching,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Matching'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.fallbackAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (state.isRunning)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(importNotifierProvider.notifier).stop(),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else if (state.isDone && state.matched > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _savePlaylist,
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: Text('Save ${state.matched} tracks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
