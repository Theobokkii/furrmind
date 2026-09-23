import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../models/distortion_result.dart';

class JournalStorageService {
  static const _boxName = 'journal_entries';
  static const _uuid = Uuid();

  Future<Box<JournalEntry>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<JournalEntry>(_boxName);
    }
    return Hive.box<JournalEntry>(_boxName);
  }

  Future<JournalEntry> saveEntry({
    required String text,
    required List<DistortionResult> distortions,
    ReframeResult? reframe,
  }) async {
    final box = await _getBox();
    final entry = JournalEntry(
      id: _uuid.v4(),
      text: text,
      distortionLabels: distortions
          .where((d) => d.triggered)
          .map((d) => d.label)
          .toList(),
      distortionConfidences: distortions
          .where((d) => d.triggered)
          .map((d) => d.confidence)
          .toList(),
      reframeText: reframe?.reframe,
      explanation: reframe?.explanation,
      techniques: reframe?.sources,
      createdAt: DateTime.now(),
    );
    await box.put(entry.id, entry);
    return entry;
  }

  Future<List<JournalEntry>> getAllEntries() async {
    final box = await _getBox();
    final entries = box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> deleteEntry(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }

  Future<int> getCount() async {
    final box = await _getBox();
    return box.length;
  }
}

final journalStorageProvider = Provider<JournalStorageService>((ref) {
  return JournalStorageService();
});

final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final storage = ref.read(journalStorageProvider);
  return storage.getAllEntries();
});
