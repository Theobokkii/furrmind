import 'package:hive/hive.dart';
class UserProfile extends HiveObject {
  String username;
  String avatarEmoji;
  int totalPoints;
  int currentLevel;
  List<String> unlockedBadges;
  UserProfile({
    required this.username,
    required this.avatarEmoji,
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.unlockedBadges = const [],
  });
}
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;
  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return UserProfile(
      username: fields[0] as String,
      avatarEmoji: fields[1] as String,
      totalPoints: fields[2] as int,
      currentLevel: fields[3] as int,
      unlockedBadges: (fields[4] as List).cast<String>(),
    );
  }
  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.username);
    writer.writeByte(1);
    writer.write(obj.avatarEmoji);
    writer.writeByte(2);
    writer.write(obj.totalPoints);
    writer.writeByte(3);
    writer.write(obj.currentLevel);
    writer.writeByte(4);
    writer.write(obj.unlockedBadges);
  }
}
