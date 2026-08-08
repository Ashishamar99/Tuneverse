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

class _ImportPlaylistScreenState extends ConsumerState<ImportPlaylistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _nameController = TextEditingController(text: 'Imported Playlist');
  final _tracksController = TextEditingController();
  bool _parsed = false;
  bool _showTokenHelp = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    _nameController.dispose();
    _tracksController.dispose();
    super.dispose();
  }

  Future<void> _fetchFromUrl() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (url.isEmpty) return;

    if (parseAmazonPlaylistId(url) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not a valid Amazon Music playlist URL')),
      );
      return;
    }

    final success = await ref
        .read(importNotifierProvider.notifier)
        .fetchFromUrl(url, token);

    if (success && mounted) {
      setState(() => _parsed = true);
    }
  }

  void _parseManual() {
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
        child: _parsed ? _buildMatchView(state) : _buildInputView(state),
      ),
    );
  }

  Widget _buildInputView(ImportState state) {
    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.fallbackAccent,
            labelColor: AppTheme.onDark,
            unselectedLabelColor: AppTheme.onDarkSecondary,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.link_rounded, size: 20),
                text: 'From URL',
              ),
              Tab(
                icon: Icon(Icons.edit_note_rounded, size: 20),
                text: 'Manual',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUrlTab(state),
              _buildManualTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrlTab(ImportState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amazon Music',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.onDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste your Amazon Music playlist link. Requires an access token from your Amazon Music web session.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onDarkSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppTheme.onDark, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Playlist URL',
              labelStyle: const TextStyle(color: AppTheme.onDarkSecondary),
              hintText: 'https://music.amazon.in/user-playlists/...',
              hintStyle: TextStyle(
                  color: AppTheme.onDarkSecondary.withValues(alpha: 0.4)),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.link_rounded,
                  color: AppTheme.onDarkSecondary, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            style: const TextStyle(color: AppTheme.onDark, fontSize: 14),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Access Token',
              labelStyle: const TextStyle(color: AppTheme.onDarkSecondary),
              hintText: 'Paste your Amazon Music access token',
              hintStyle: TextStyle(
                  color: AppTheme.onDarkSecondary.withValues(alpha: 0.4)),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.key_rounded,
                  color: AppTheme.onDarkSecondary, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showTokenHelp = !_showTokenHelp),
            child: Row(
              children: [
                Icon(
                  _showTokenHelp
                      ? Icons.expand_less_rounded
                      : Icons.help_outline_rounded,
                  color: AppTheme.fallbackAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'How do I get my access token?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.fallbackAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_showTokenHelp) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.fallbackAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '1. Open music.amazon.in in Chrome\n'
                '2. Sign in with your Amazon/Prime account\n'
                '3. Press F12 → Network tab\n'
                '4. Play any song or open a playlist\n'
                '5. Look for API requests → find the "Authorization" header\n'
                '6. Copy the token after "Bearer "',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onDarkSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: state.isFetchingUrl ? null : _fetchFromUrl,
              icon: state.isFetchingUrl
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                state.isFetchingUrl ? 'Fetching...' : 'Fetch Playlist',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.fallbackAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.fallbackAccent.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Requires Amazon Prime account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.onDarkSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
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
            maxLines: 12,
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
            'Tip: Copy your track list from Amazon Music, Spotify, or any music app and paste here.',
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
                  _tracksController.text.trim().isEmpty ? null : _parseManual,
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
                _buildTrackTile(state.tracks[index]),
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
          if (state.playlistName != null &&
              state.playlistName != 'Imported Playlist')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.playlistName!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onDark,
                ),
              ),
            ),
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

  Widget _buildTrackTile(ImportTrack track) {
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
                label: const Text('Match on YouTube'),
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
