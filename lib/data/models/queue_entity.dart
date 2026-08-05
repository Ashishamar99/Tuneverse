import 'package:isar/isar.dart';
import 'package:just_audio/just_audio.dart';

part 'queue_entity.g.dart';

@collection
class QueueEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String profileId;

  List<int> trackIds = [];
  int currentIndex = 0;

  @enumerated
  LoopMode loopMode = LoopMode.off;

  bool shuffled = false;
}
