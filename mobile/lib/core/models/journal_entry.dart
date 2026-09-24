import 'package:hive/hive.dart';
class JournalEntry extends HiveObject {
  String id;
  String text;
  List<String> distortionLabels;
  List<double> distortionConfidences;
  String? reframeText;
  String? explanation;
  List<String>? techniques;
  DateTime createdAt;
  JournalEntry({
    required this.id,
    required this.text,
    required this.distortionLabels,
    required this.distortionConfidences,
    this.reframeText,
    this.explanation,
    this.techniques,
    required this.createdAt,
  });
}
class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 0;
  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return JournalEntry(
      id: fields[0] as String,
      text: fields[1] as String,
      distortionLabels: (fields[2] as List).cast<String>(),
      distortionConfidences: (fields[3] as List).cast<double>(),
      reframeText: fields[4] as String?,
      explanation: fields[5] as String?,
      techniques: (fields[6] as List?)?.cast<String>(),
      createdAt: fields[7] as DateTime,
    );
  }
  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.text);
    writer.writeByte(2);
    writer.write(obj.distortionLabels);
    writer.writeByte(3);
    writer.write(obj.distortionConfidences);
    writer.writeByte(4);
    writer.write(obj.reframeText);
    writer.writeByte(5);
    writer.write(obj.explanation);
    writer.writeByte(6);
    writer.write(obj.techniques);
    writer.writeByte(7);
    writer.write(obj.createdAt);
  }
}
