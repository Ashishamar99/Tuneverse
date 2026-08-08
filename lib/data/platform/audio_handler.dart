import 'package:audio_service/audio_service.dart';
import 'package:isar/isar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/domain/entities/track.dart';

class TuneVerseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AndroidEqualizer _equalizer = AndroidEqualizer();
  late final AudioPlayer _player;
  final Isar _isar;
  Future<Uri> Function(String sourceId, {bool useMuxed})? _youtubeResolver;

  bool _isCasting = false;
  void Function(Duration)? _castSeekCallback;

  static const _recentId = 'recent';
  static const _libraryId = 'library';
  static const _playlistsId = 'playlists';
  static const _playlistPrefix = 'playlist_';

  static const seekBackwardAction = 'seekBackward10';
  static const seekForwardAction = 'seekForward10';
  static const toggleFavoriteAction = 'toggleFavorite';

  void setYouTubeResolver(
      Future<Uri> Function(String sourceId, {bool useMuxed}) resolver) {
    _youtubeResolver = resolver;
  }

  AndroidEqualizer get equalizer => _equalizer;

  void setCasting(bool casting, {
    void Function(Duration)? onSeek,
  }) {
    _isCasting = casting;
    _castSeekCallback = onSeek;
    _player.playbackEventStream.first.then((e) {
      playbackState.add(_transformEvent(e));
    });
  }

  bool get isCasting => _isCasting;

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
          const MediaItem(
            id: _playlistsId,
            title: 'Playlists',
            playable: false,
          ),
        ];
      case _recentId:
        return _recentTracks();
      case _libraryId:
        return _libraryTracks();
      case _playlistsId:
        return _playlistItems();
      default:
        if (parentMediaId.startsWith(_playlistPrefix)) {
          final id = int.tryParse(
              parentMediaId.substring(_playlistPrefix.length));
          if (id != null) return _playlistTracks(id);
        }
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

  Future<List<MediaItem>> _playlistItems() async {
    final playlists = await _isar.playlistEntitys
        .where()
        .sortByUpdatedAtDesc()
        .limit(50)
        .findAll();
    return playlists.map((pl) => MediaItem(
      id: '$_playlistPrefix${pl.id}',
      title: pl.name,
      playable: false,
    )).toList();
  }

  Future<List<MediaItem>> _playlistTracks(int playlistId) async {
    final playlist = await _isar.playlistEntitys.get(playlistId);
    if (playlist == null) return [];
    final items = <MediaItem>[];
    for (final trackId in playlist.trackIds) {
      final entity = await _isar.trackEntitys.get(trackId);
      if (entity != null) items.add(_entityToMediaItem(entity));
    }
    return items;
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

  // --- Custom actions (Android Auto + cast notification) ---

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case seekBackwardAction:
        if (_isCasting && _castSeekCallback != null) {
          _castSeekCallback!(const Duration(seconds: -10));
        } else {
          final pos = _player.position - const Duration(seconds: 10);
          await _player.seek(pos < Duration.zero ? Duration.zero : pos);
        }
      case seekForwardAction:
        if (_isCasting && _castSeekCallback != null) {
          _castSeekCallback!(const Duration(seconds: 10));
        } else {
          final pos = _player.position + const Duration(seconds: 10);
          final dur = _player.duration;
          await _player.seek(dur != null && pos > dur ? dur : pos);
        }
      case toggleFavoriteAction:
        _onToggleFavorite?.call();
    }
  }

  void Function()? _onToggleFavorite;
  void setFavoriteCallback(void Function() callback) {
    _onToggleFavorite = callback;
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

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (_queueSource == null) return;
    await _queueSource!.move(oldIndex, newIndex);
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
    final controls = <MediaControl>[];

    if (_isCasting) {
      controls.addAll([
        MediaControl.skipToPrevious,
        MediaControl.custom(
          androidIcon: 'drawable/audio_service_fast_rewind',
          label: '-10s',
          name: seekBackwardAction,
        ),
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.custom(
          androidIcon: 'drawable/audio_service_fast_forward',
          label: '+10s',
          name: seekForwardAction,
        ),
        MediaControl.skipToNext,
      ]);
    } else {
      controls.addAll([
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ]);
    }

    return PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: _isCasting
          ? const [0, 2, 4]
          : const [0, 1, 2],
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
