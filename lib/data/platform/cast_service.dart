import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

const _kDefaultReceiverAppId = 'CC1AD845';

class CastService {
  static final CastService _instance = CastService._();
  factory CastService() => _instance;
  CastService._();

  bool _initialized = false;
  final _castingController = StreamController<bool>.broadcast();
  final _deviceNameController = StreamController<String?>.broadcast();

  Stream<bool> get isCastingStream => _castingController.stream;
  Stream<String?> get deviceNameStream => _deviceNameController.stream;

  GoogleCastRemoteMediaClientPlatformInterface get _media =>
      GoogleCastRemoteMediaClient.instance;

  GoogleCastSessionManagerPlatformInterface get _session =>
      GoogleCastSessionManager.instance;

  GoogleCastDiscoveryManagerPlatformInterface get _discovery =>
      GoogleCastDiscoveryManager.instance;

  bool get isCasting => _session.hasConnectedSession;
  String? get connectedDeviceName => _session.currentSession?.device?.friendlyName;
  List<GoogleCastDevice> get devices => _discovery.devices;
  Stream<List<GoogleCastDevice>> get devicesStream => _discovery.devicesStream;

  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _media.mediaStatusStream;
  Stream<Duration> get castPositionStream => _media.playerPositionStream;

  Future<void> init() async {
    if (_initialized) return;

    // Bypass broken GoogleCastOptions.toMap() which omits required appId
    const channel = MethodChannel('com.felnanuke.google_cast.context');
    await channel.invokeMethod('setSharedInstance', {
      'appId': _kDefaultReceiverAppId,
      'physicalVolumeButtonsWillControlDeviceVolume': true,
      'disableDiscoveryAutostart': false,
      'disableAnalyticsLogging': true,
      'suspendSessionsWhenBackgrounded': true,
      'stopReceiverApplicationWhenEndingSession': false,
      'startDiscoveryAfterFirstTapOnCastButton': true,
      'stopCastingOnAppTerminated': true,
    });

    _session.currentSessionStream.listen((session) {
      final connected = session != null;
      _castingController.add(connected);
      _deviceNameController.add(session?.device?.friendlyName);
    });

    _initialized = true;
  }

  Future<void> startDiscovery() => _discovery.startDiscovery();
  Future<void> stopDiscovery() => _discovery.stopDiscovery();

  Future<bool> connectToDevice(GoogleCastDevice device) =>
      _session.startSessionWithDevice(device);

  Future<bool> disconnect() => _session.endSessionAndStopCasting();

  Future<void> loadMedia({
    required Uri streamUri,
    required String title,
    required String artist,
    String? artworkUrl,
    Duration? duration,
    String contentType = 'audio/mp4',
  }) async {
    final metadata = GoogleCastMusicMediaMetadata(
      title: title,
      artist: artist,
      images: artworkUrl != null
          ? [GoogleCastImage(url: Uri.parse(artworkUrl))]
          : null,
    );

    final mediaInfo = GoogleCastMediaInformation(
      contentId: streamUri.toString(),
      streamType: CastMediaStreamType.buffered,
      contentType: contentType,
      metadata: metadata,
      duration: duration,
      contentUrl: streamUri,
    );

    await _media.loadMedia(mediaInfo, autoPlay: true);
  }

  Future<void> play() => _media.play();
  Future<void> pause() => _media.pause();
  Future<void> stop() => _media.stop();

  Future<void> seek(Duration position) => _media.seek(
        GoogleCastMediaSeekOption(position: position),
      );

  void dispose() {
    _castingController.close();
    _deviceNameController.close();
  }
}
