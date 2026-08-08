import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/playlist_providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/domain/entities/track.dart';

enum ImportTrackStatus { pending, matching, matched, notFound }

class ImportTrack {
  final String artist;
  final String title;
  final Track? matchedTrack;
  final ImportTrackStatus status;

  const ImportTrack({
    required this.artist,
    required this.title,
    this.matchedTrack,
    this.status = ImportTrackStatus.pending,
  });

  ImportTrack copyWith({
    Track? matchedTrack,
    ImportTrackStatus? status,
  }) {
    return ImportTrack(
      artist: artist,
      title: title,
      matchedTrack: matchedTrack ?? this.matchedTrack,
      status: status ?? this.status,
    );
  }

  String get query => '$artist $title';
}

class ImportState {
  final List<ImportTrack> tracks;
  final bool isRunning;
  final String? playlistName;
  final String? error;

  const ImportState({
    this.tracks = const [],
    this.isRunning = false,
    this.playlistName,
    this.error,
  });

  int get matched => tracks.where((t) => t.status == ImportTrackStatus.matched).length;
  int get notFound => tracks.where((t) => t.status == ImportTrackStatus.notFound).length;
  int get pending => tracks.where((t) =>
      t.status == ImportTrackStatus.pending ||
      t.status == ImportTrackStatus.matching).length;
  bool get isDone => !isRunning && tracks.isNotEmpty && pending == 0;

  ImportState copyWith({
    List<ImportTrack>? tracks,
    bool? isRunning,
    String? playlistName,
    String? error,
  }) {
    return ImportState(
      tracks: tracks ?? this.tracks,
      isRunning: isRunning ?? this.isRunning,
      playlistName: playlistName ?? this.playlistName,
      error: error ?? this.error,
    );
  }
}

class ImportNotifier extends StateNotifier<ImportState> {
  final Ref _ref;

  ImportNotifier(this._ref) : super(const ImportState());

  void parseInput(String text, {String? playlistName}) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final tracks = <ImportTrack>[];
    for (final line in lines) {
      final parts = _parseLine(line);
      tracks.add(ImportTrack(artist: parts.$1, title: parts.$2));
    }

    state = ImportState(
      tracks: tracks,
      playlistName: playlistName ?? 'Imported Playlist',
    );
  }

  (String, String) _parseLine(String line) {
    // Remove leading numbering: "1. ", "01 - ", "1) ", etc.
    line = line.replaceFirst(RegExp(r'^\d+[\.\)\-\s]+\s*'), '');

    // Try "Artist - Title" or "Artist — Title"
    for (final sep in [' - ', ' — ', ' – ', ' | ']) {
      final idx = line.indexOf(sep);
      if (idx > 0) {
        return (line.substring(0, idx).trim(), line.substring(idx + sep.length).trim());
      }
    }

    // No separator found — treat entire line as the title
    return ('', line);
  }

  Future<void> startMatching() async {
    if (state.tracks.isEmpty) return;
    state = state.copyWith(isRunning: true, error: null);

    final youtube = _ref.read(youtubeSourceProvider);

    for (var i = 0; i < state.tracks.length; i++) {
      if (!state.isRunning) break;

      final track = state.tracks[i];
      final updated = List<ImportTrack>.from(state.tracks);
      updated[i] = track.copyWith(status: ImportTrackStatus.matching);
      state = state.copyWith(tracks: updated);

      try {
        final results = await youtube.searchMusicOnly(track.query, limit: 3);
        final updated2 = List<ImportTrack>.from(state.tracks);
        if (results.isNotEmpty) {
          updated2[i] = track.copyWith(
            matchedTrack: results.first,
            status: ImportTrackStatus.matched,
          );
        } else {
          updated2[i] = track.copyWith(status: ImportTrackStatus.notFound);
        }
        state = state.copyWith(tracks: updated2);
      } catch (_) {
        final updated2 = List<ImportTrack>.from(state.tracks);
        updated2[i] = track.copyWith(status: ImportTrackStatus.notFound);
        state = state.copyWith(tracks: updated2);
      }
    }

    state = state.copyWith(isRunning: false);
  }

  void stop() {
    state = state.copyWith(isRunning: false);
  }

  Future<int?> createPlaylist() async {
    final matched = state.tracks
        .where((t) => t.status == ImportTrackStatus.matched && t.matchedTrack != null)
        .toList();

    if (matched.isEmpty) return null;

    final name = state.playlistName ?? 'Imported Playlist';
    final create = _ref.read(createPlaylistProvider);
    final addTo = _ref.read(addToPlaylistProvider);

    final playlist = await create(name);
    for (final t in matched) {
      await addTo(playlist.id, t.matchedTrack!);
    }

    _ref.invalidate(playlistsProvider);
    return playlist.id;
  }

  void reset() {
    state = const ImportState();
  }
}

final importNotifierProvider =
    StateNotifierProvider<ImportNotifier, ImportState>((ref) {
  return ImportNotifier(ref);
});
