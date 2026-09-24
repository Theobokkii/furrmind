import 'package:hive/hive.dart';
class MoodEntry extends HiveObject {
  String id;
  int moodScore;
  DateTime createdAt;
  MoodEntry({
    required this.id,
    required this.moodScore,
    required this.createdAt,
  });
}
class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 2;
  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return MoodEntry(
      id: fields[0] as String,
      moodScore: fields[1] as int,
      createdAt: fields[2] as DateTime,
    );
  }
  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.moodScore);
    writer.writeByte(2);
    writer.write(obj.createdAt);
  }
}
