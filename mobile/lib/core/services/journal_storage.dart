import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../models/distortion_result.dart';
import 'gamification_service.dart';
import 'firestore_service.dart';

class JournalStorageService {
  static const _uuid = Uuid();
  final Ref ref;
  JournalStorageService(this.ref);

  Future<JournalEntry> saveEntry({
    required String text,
    required List<DistortionResult> distortions,
    ReframeResult? reframe,
  }) async {
    final firestoreService = ref.read(firestoreServiceProvider);

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
    
    await firestoreService.saveJournalEntry(entry);
    
    final gamification = ref.read(gamificationProvider);
    int pointsEarned = 10;
    if (reframe != null) pointsEarned += 15;
    await gamification.addPoints(pointsEarned);
    
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.deleteJournalEntry(id);
  }
}
final journalStorageProvider = Provider<JournalStorageService>((ref) {
  return JournalStorageService(ref);
});
final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getJournalsStream();
});
