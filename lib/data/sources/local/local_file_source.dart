import 'package:isar/isar.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:tuneverse/core/constants/app_constants.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';
import 'package:tuneverse/domain/interfaces/track_source.dart';

class LocalFileSource implements TrackSource {
  final OnAudioQuery _audioQuery;
  final Isar _isar;

  LocalFileSource(this._isar) : _audioQuery = OnAudioQuery();

  @override
  Future<List<Track>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final entities = await _isar.trackEntitys
        .filter()
        .sourceTypeEqualTo(TrackSourceType.local)
        .group((q) => q
            .titleContains(query, caseSensitive: false)
            .or()
            .artistContains(query, caseSensitive: false))
        .sortByTitle()
        .findAll();
    return entities.take(limit).map((e) => e.toDomain()).toList();
  }

  @override
  Future<Uri> getStreamUri(Track track) async {
    return Uri.file(track.localPath!);
  }

  @override
  Future<Track?> resolve(String sourceId) async {
    final entity = await _isar.trackEntitys
        .getBySourceIdSourceType(sourceId, TrackSourceType.local);
    return entity?.toDomain();
  }

  Future<List<Track>> scanDevice() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    final tracks = <Track>[];
    for (final song in songs) {
      if (!_isSupported(song)) continue;
      tracks.add(Track(
        id: '',
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        album: song.album,
        durationMs: song.duration,
        // MediaStore ID stored here for QueryArtworkWidget in the UI layer.
        artworkUrl: song.id.toString(),
        sourceType: TrackSourceType.local,
        sourceId: song.data,
        localPath: song.data,
      ));
    }

    await _persistTracks(tracks);
    return tracks;
  }

  bool _isSupported(SongModel song) {
    final path = song.data;
    final dotIdx = path.lastIndexOf('.');
    if (dotIdx < 0) return false;
    final ext = path.substring(dotIdx).toLowerCase();
    if (!AppConstants.supportedAudioExtensions.contains(ext)) return false;
    if (song.size < AppConstants.minAudioFileSizeBytes) return false;
    final durationMs = song.duration ?? 0;
    if (durationMs < AppConstants.minAudioDurationSeconds * 1000) return false;
    return true;
  }

  Future<void> _persistTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    await _isar.writeTxn(() async {
      final sourceIds = tracks.map((t) => t.sourceId).toList();
      final sourceTypes = List.filled(tracks.length, TrackSourceType.local);
      final existing = await _isar.trackEntitys
          .getAllBySourceIdSourceType(sourceIds, sourceTypes);

      final newEntities = <TrackEntity>[];
      for (var i = 0; i < tracks.length; i++) {
        if (existing[i] == null) {
          newEntities.add(TrackEntity.fromDomain(tracks[i]));
        }
      }

      if (newEntities.isNotEmpty) {
        await _isar.trackEntitys.putAll(newEntities);
      }
    });
  }
}
