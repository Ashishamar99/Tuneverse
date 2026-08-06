import 'package:tuneverse/domain/entities/track.dart';

abstract class TrackSource {
  Future<List<Track>> search(String query, {int limit = 20});
  Future<Uri> getStreamUri(Track track, {bool useMuxed = false});
  Future<Track?> resolve(String sourceId);
}
