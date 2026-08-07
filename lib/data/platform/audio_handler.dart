import 'package:audio_service/audio_service.dart';
import 'package:isar/isar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

class TuneVerseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AndroidEqualizer _equalizer = AndroidEqualizer();
  late final AudioPlayer _player;
  final Isar _isar;
  Future<Uri> Function(String sourceId, {bool useMuxed})? _youtubeResolver;

  static const _recentId = 'recent';
  static const _libraryId = 'library';

  void setYouTubeResolver(
      Future<Uri> Function(String sourceId, {bool useMuxed}) resolver) {
    _youtubeResolver = resolver;
  }

  AndroidEqualizer get equalizer => _equalizer;

  TuneVerseAudioHandler(this._isar) {
    _player = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [_equalizer],
      ),
    );
    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });
    _player.sequenceStateStream.listen((state) {
      if (state == null) return;
      final sequence = state.effectiveSequence;
      if (sequence.isEmpty) return;
      queue.add(sequence.map((s) => s.tag as MediaItem).toList());
      final index = state.currentIndex;
      if (index >= 0 && index < sequence.length) {
        mediaItem.add(sequence[index].tag as MediaItem);
      }
    });
  }

  // --- Android Auto content tree ---

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    switch (parentMediaId) {
      case AudioService.browsableRootId:
        return [
          const MediaItem(
            id: _recentId,
            title: 'Recently Played',
            playable: false,
          ),
          const MediaItem(
            id: _libraryId,
            title: 'Library',
            playable: false,
          ),
        ];
      case _recentId:
        return _recentTracks();
      case _libraryId:
        return _libraryTracks();
      default:
        return [];
    }
  }

  Future<List<MediaItem>> _recentTracks() async {
    final entities = await _isar.trackEntitys
        .filter()
        .lastPlayedAtIsNotNull()
        .sortByLastPlayedAtDesc()
        .limit(30)
        .findAll();
    return entities.map(_entityToMediaItem).toList();
  }

  Future<List<MediaItem>> _libraryTracks() async {
    final entities = await _isar.trackEntitys
        .filter()
        .sourceTypeEqualTo(TrackSourceType.local)
        .sortByTitle()
        .limit(100)
        .findAll();
    return entities.map(_entityToMediaItem).toList();
  }

  MediaItem _entityToMediaItem(TrackEntity e) {
    Uri? artUri;
    if (e.artworkUrl != null && e.artworkUrl!.startsWith('http')) {
      artUri = Uri.tryParse(e.artworkUrl!);
    }
    return MediaItem(
      id: '${e.sourceType.name}:${e.sourceId}',
      title: e.title,
      artist: e.artist,
      album: e.album,
      duration: e.durationMs != null
          ? Duration(milliseconds: e.durationMs!)
          : null,
      artUri: artUri,
    );
  }

  // --- Stamp play history for Android Auto "Recently Played" ---

  void recordPlay(Track track) {
    _isar.writeTxn(() async {
      final entity = await _isar.trackEntitys
          .getBySourceIdSourceType(track.sourceId, track.sourceType);
      if (entity != null) {
        entity
          ..playCount += 1
          ..lastPlayedAt = DateTime.now();
        await _isar.trackEntitys.put(entity);
      }
    });
  }

  // --- Android Auto: play from browse tree ---

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    final parts = mediaId.split(':');
    if (parts.length != 2) return;

    final sourceType = TrackSourceType.values.firstWhere(
      (t) => t.name == parts[0],
      orElse: () => TrackSourceType.youtube,
    );

    final entity = await _isar.trackEntitys
        .getBySourceIdSourceType(parts[1], sourceType);
    if (entity == null) return;

    Uri uri;
    if (entity.localPath != null && entity.isDownloaded) {
      uri = Uri.file(entity.localPath!);
    } else if (_youtubeResolver != null) {
      try {
        uri = await _youtubeResolver!(parts[1]);
      } catch (_) {
        try {
          uri = await _youtubeResolver!(parts[1], useMuxed: true);
        } catch (_) {
          return;
        }
      }
    } else {
      return;
    }

    final item = _entityToMediaItem(entity);
    await playTrack(item, uri);
    recordPlay(entity.toDomain());
  }

  // --- Playback controls ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode != AudioServiceShuffleMode.none,
    );
  }

  ConcatenatingAudioSource? _queueSource;

  Future<void> playTrack(MediaItem item, Uri uri, {Map<String, String>? headers}) async {
    mediaItem.add(item);
    _queueSource = ConcatenatingAudioSource(
      children: [AudioSource.uri(uri, tag: item, headers: headers)],
    );
    await _player.setAudioSource(_queueSource!);
    await _player.play();
  }

  Future<void> loadQueue(List<(MediaItem, Uri)> items, {int initialIndex = 0, Map<String, String>? headers}) async {
    final sources = items
        .map((pair) => AudioSource.uri(pair.$2, tag: pair.$1, headers: headers))
        .toList();
    _queueSource = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(
      _queueSource!,
      initialIndex: initialIndex,
    );
  }

  Future<void> addToQueue(MediaItem item, Uri uri) async {
    if (_queueSource == null) {
      return playTrack(item, uri);
    }
    await _queueSource!.add(AudioSource.uri(uri, tag: item));
  }

  Future<void> insertAfterCurrent(MediaItem item, Uri uri) async {
    if (_queueSource == null) {
      return playTrack(item, uri);
    }
    final currentIndex = _player.currentIndex ?? 0;
    await _queueSource!.insert(
      currentIndex + 1,
      AudioSource.uri(uri, tag: item),
    );
  }

  Future<void> clearQueue() async {
    await _player.stop();
    _queueSource = null;
    queue.add([]);
    mediaItem.add(null);
  }

  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
