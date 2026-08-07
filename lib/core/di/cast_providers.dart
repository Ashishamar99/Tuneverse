import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:tuneverse/data/platform/cast_service.dart';

final castServiceProvider = Provider<CastService>((ref) => CastService());

final isCastingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(castServiceProvider);
  return service.isCastingStream;
});

final castDeviceNameProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(castServiceProvider);
  return service.deviceNameStream;
});

final castDevicesProvider = StreamProvider<List<GoogleCastDevice>>((ref) {
  final service = ref.watch(castServiceProvider);
  return service.devicesStream;
});

final castMediaStatusProvider = StreamProvider<GoggleCastMediaStatus?>((ref) {
  final service = ref.watch(castServiceProvider);
  return service.mediaStatusStream;
});

final castPositionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(castServiceProvider);
  return service.castPositionStream;
});
