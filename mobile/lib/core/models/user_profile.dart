import 'package:hive/hive.dart';
class UserProfile extends HiveObject {
  String name;
  String username;
  String avatarEmoji;
  int totalPoints;
  int currentLevel;
  List<String> unlockedBadges;
  String pronouns;
  String bio;
  List<String> friendIds;
  List<String> pendingFriendRequests;
  List<String> sentFriendRequests;
  String bannerUrl;
  String activeTheme;
  UserProfile({
    required this.name,
    required this.username,
    required this.avatarEmoji,
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.unlockedBadges = const [],
    this.pronouns = '',
    this.bio = '',
    this.friendIds = const [],
    this.pendingFriendRequests = const [],
    this.sentFriendRequests = const [],
    this.bannerUrl = 'default',
    this.activeTheme = 'default',
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
      name: (fields[10] as String?) ?? (fields[0] as String), // fallback to username
      username: fields[0] as String,
      avatarEmoji: fields[1] as String,
      totalPoints: fields[2] as int,
      currentLevel: fields[3] as int,
      unlockedBadges: (fields[4] as List?)?.cast<String>() ?? [],
      pronouns: fields[5] as String? ?? '',
      bio: fields[6] as String? ?? '',
      friendIds: (fields[7] as List?)?.cast<String>() ?? [],
      pendingFriendRequests: (fields[11] as List?)?.cast<String>() ?? [],
      sentFriendRequests: (fields[12] as List?)?.cast<String>() ?? [],
      bannerUrl: fields[8] as String? ?? 'default',
      activeTheme: fields[9] as String? ?? 'default',
    );
  }
  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeByte(13);
    writer.writeByte(12);
    writer.write(obj.sentFriendRequests);
    writer.writeByte(11);
    writer.write(obj.pendingFriendRequests);
    writer.writeByte(10);
    writer.write(obj.name);
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
    writer.writeByte(5);
    writer.write(obj.pronouns);
    writer.writeByte(6);
    writer.write(obj.bio);
    writer.writeByte(7);
    writer.write(obj.friendIds);
    writer.writeByte(8);
    writer.write(obj.bannerUrl);
    writer.writeByte(9);
    writer.write(obj.activeTheme);
  }
}
