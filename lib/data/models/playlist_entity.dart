import 'package:isar/isar.dart';

part 'playlist_entity.g.dart';

@collection
class PlaylistEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late String profileId;

  late String name;
  String? description;
  String? artworkUrl;

  List<int> trackIds = [];

  late DateTime createdAt;
  late DateTime updatedAt;
}
