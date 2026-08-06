import 'package:isar/isar.dart';
import 'package:tuneverse/domain/entities/track.dart';

part 'track_entity.g.dart';

@collection
class TrackEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String title;

  @Index()
  late String artist;

  String? album;
  int? durationMs;
  String? artworkUrl;

  @enumerated
  late TrackSourceType sourceType;

  @Index(unique: true, composite: [CompositeIndex('sourceType')])
  late String sourceId;

  String? localPath;
  DateTime? downloadedAt;
  int playCount = 0;
  DateTime? lastPlayedAt;
  bool isFavorite = false;

  bool get isDownloaded => downloadedAt != null && localPath != null;

  Track toDomain() => Track(
        id: id.toString(),
        title: title,
        artist: artist,
        album: album,
        durationMs: durationMs,
        artworkUrl: artworkUrl,
        sourceType: sourceType,
        sourceId: sourceId,
        localPath: localPath,
        isDownloaded: isDownloaded,
        isFavorite: isFavorite,
      );

  static TrackEntity fromDomain(Track track) {
    final entity = TrackEntity()
      ..title = track.title
      ..artist = track.artist
      ..album = track.album
      ..durationMs = track.durationMs
      ..artworkUrl = track.artworkUrl
      ..sourceType = track.sourceType
      ..sourceId = track.sourceId
      ..localPath = track.localPath;
    if (track.id.isNotEmpty && int.tryParse(track.id) != null) {
      entity.id = int.parse(track.id);
    }
    return entity;
  }
}
