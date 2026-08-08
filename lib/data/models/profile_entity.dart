import 'package:isar/isar.dart';

part 'profile_entity.g.dart';

@collection
class ProfileEntity {
  Id id = Isar.autoIncrement;

  late String name;
  late String avatarEmoji;
  late int accentColorValue;
  late DateTime createdAt;
  bool isActive = false;
  List<String> favoriteSourceIds = [];
}
