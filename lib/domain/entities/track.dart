import 'package:equatable/equatable.dart';

enum TrackSourceType { youtube, local, cached }

class Track extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final int? durationMs;
  final String? artworkUrl;
  final TrackSourceType sourceType;
  final String sourceId;
  final String? localPath;
  final bool isDownloaded;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationMs,
    this.artworkUrl,
    required this.sourceType,
    required this.sourceId,
    this.localPath,
    this.isDownloaded = false,
  });

  Duration? get duration =>
      durationMs != null ? Duration(milliseconds: durationMs!) : null;

  bool get isLocal => sourceType == TrackSourceType.local || isDownloaded;

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    String? artworkUrl,
    TrackSourceType? sourceType,
    String? sourceId,
    String? localPath,
    bool? isDownloaded,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [id, sourceType, sourceId];
}
