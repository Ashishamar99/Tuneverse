import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuneverse/core/constants/app_constants.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/data/sources/youtube/youtube_source.dart';
import 'package:tuneverse/domain/entities/track.dart';

enum DownloadStatus { queued, downloading, completed, failed }

class DownloadProgress {
  final String trackId;
  final double progress;
  final DownloadStatus status;

  const DownloadProgress({
    required this.trackId,
    required this.progress,
    required this.status,
  });
}

class DownloadManager {
  final Isar _isar;
  final YouTubeSource _youtubeSource;
  final Dio _dio = Dio();

  final _progressController =
      StreamController<DownloadProgress>.broadcast();
  final Map<String, CancelToken> _activeTokens = {};
  final List<_QueuedDownload> _queue = [];
  int _activeCount = 0;

  DownloadManager(this._isar, this._youtubeSource);

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Future<String> download(Track track) async {
    final completer = Completer<String>();
    _queue.add(_QueuedDownload(track: track, completer: completer));

    _emitProgress(track.sourceId, 0.0, DownloadStatus.queued);
    _processQueue();

    return completer.future;
  }

  void _processQueue() {
    while (_activeCount < AppConstants.maxConcurrentDownloads &&
        _queue.isNotEmpty) {
      final queued = _queue.removeAt(0);
      _activeCount++;
      _startDownload(queued);
    }
  }

  Future<void> _startDownload(_QueuedDownload queued) async {
    final track = queued.track;
    final sourceId = track.sourceId;
    final cancelToken = CancelToken();
    _activeTokens[sourceId] = cancelToken;

    try {
      _emitProgress(sourceId, 0.0, DownloadStatus.downloading);

      final uri = await _youtubeSource.getStreamUri(track);

      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final filePath = '${downloadsDir.path}/$sourceId.m4a';

      await _dio.download(
        uri.toString(),
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _emitProgress(
              sourceId,
              received / total,
              DownloadStatus.downloading,
            );
          }
        },
      );

      await _isar.writeTxn(() async {
        var entity = await _isar.trackEntitys
            .getBySourceIdSourceType(sourceId, track.sourceType);
        entity ??= TrackEntity.fromDomain(track);
        entity
          ..localPath = filePath
          ..downloadedAt = DateTime.now();
        await _isar.trackEntitys.put(entity);
      });

      _emitProgress(sourceId, 1.0, DownloadStatus.completed);
      queued.completer.complete(filePath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _emitProgress(sourceId, 0.0, DownloadStatus.failed);
        queued.completer
            .completeError(Exception('Download cancelled for $sourceId'));
      } else {
        _emitProgress(sourceId, 0.0, DownloadStatus.failed);
        queued.completer.completeError(e);
      }
    } catch (e) {
      _emitProgress(sourceId, 0.0, DownloadStatus.failed);
      queued.completer.completeError(e);
    } finally {
      _activeTokens.remove(sourceId);
      _activeCount--;
      _processQueue();
    }
  }

  void cancelDownload(String sourceId) {
    final token = _activeTokens[sourceId];
    if (token != null) {
      token.cancel();
      return;
    }
    // Remove from queue if still waiting.
    final index =
        _queue.indexWhere((q) => q.track.sourceId == sourceId);
    if (index != -1) {
      final removed = _queue.removeAt(index);
      _emitProgress(sourceId, 0.0, DownloadStatus.failed);
      removed.completer
          .completeError(Exception('Download cancelled for $sourceId'));
    }
  }

  bool isDownloaded(String sourceId) {
    final entity = _isar.trackEntitys
        .getBySourceIdSourceTypeSync(sourceId, TrackSourceType.youtube);
    return entity?.isDownloaded ?? false;
  }

  void _emitProgress(
    String trackId,
    double progress,
    DownloadStatus status,
  ) {
    _progressController.add(DownloadProgress(
      trackId: trackId,
      progress: progress,
      status: status,
    ));
  }

  void dispose() {
    for (final token in _activeTokens.values) {
      token.cancel();
    }
    _progressController.close();
    _dio.close();
  }
}

class _QueuedDownload {
  final Track track;
  final Completer<String> completer;

  _QueuedDownload({required this.track, required this.completer});
}
