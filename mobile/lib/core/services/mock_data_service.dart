import 'dart:ui';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
class MockDataService {
  static const _uuid = Uuid();
  static const _boxName = 'journal_entries';
  static const _seedKey = 'mock_data_seeded';
  static Future<void> seedIfNeeded() async {
    final settingsBox = await Hive.openBox('settings');
    final alreadySeeded = settingsBox.get(_seedKey, defaultValue: false);
    if (alreadySeeded == true) return;
    final box = await Hive.openBox<JournalEntry>(_boxName);
    if (box.isNotEmpty) {
      await settingsBox.put(_seedKey, true);
      return;
    }
    final now = DateTime.now();
    final entries = [
      JournalEntry(
        id: _uuid.v4(),
        text:
            'I completely failed my presentation today. Everyone must think I am incompetent. I will never be good at public speaking.',
        distortionLabels: ['all_or_nothing', 'mind_reading', 'fortune_telling'],
        distortionConfidences: [0.92, 0.85, 0.78],
        reframeText:
            'The presentation had some rough moments, but I also covered all my key points. One experience doesn\'t define my ability — each presentation is a chance to improve.',
        explanation:
            'This thought uses all-or-nothing thinking by saying you "completely failed." Mind reading assumes everyone thinks badly of you, and fortune telling predicts you\'ll never improve. In reality, skills develop with practice.',
        techniques: [
          'Cognitive Restructuring',
          'Evidence Examination',
          'Behavioral Experiments',
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        text:
            'My friend didn\'t reply to my message. She probably doesn\'t want to be friends anymore. I always end up alone.',
        distortionLabels: [
          'jumping_to_conclusions',
          'overgeneralization',
          'catastrophizing',
        ],
        distortionConfidences: [0.88, 0.82, 0.71],
        reframeText:
            'There are many reasons someone might not reply right away — they could be busy, distracted, or just forgot. One delayed reply doesn\'t mean the friendship is over.',
        explanation:
            'Jumping to conclusions means assuming the worst without evidence. Overgeneralization turns one event into a pattern ("always"). Catastrophizing imagines the worst-case scenario.',
        techniques: [
          'Thought Record',
          'Perspective Taking',
          'Decatastrophizing',
        ],
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        text:
            'Had a really productive morning. Finished two tasks before lunch and even helped a colleague with their bug. Feeling pretty good about today.',
        distortionLabels: [],
        distortionConfidences: [],
        reframeText: null,
        explanation: null,
        techniques: null,
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        text:
            'I should be exercising every day. I\'m so lazy for skipping the gym this week. Other people manage to work out no matter how busy they are.',
        distortionLabels: ['should_statements', 'labeling', 'mental_filter'],
        distortionConfidences: [0.90, 0.76, 0.68],
        reframeText:
            'It\'s okay to miss the gym sometimes. Rest is part of a healthy routine too. Instead of labeling yourself "lazy," recognize that you had a busy week and can start fresh.',
        explanation:
            '"Should" statements create guilt and pressure. Labeling yourself "lazy" is a fixed, harsh judgment. Mental filter ignores the things you did accomplish this week.',
        techniques: [
          'Self-Compassion',
          'Flexible Thinking',
          'Balanced Self-Assessment',
        ],
        createdAt: now.subtract(const Duration(days: 3, hours: 8)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        text:
            'Got positive feedback on my code review today. But it was probably just a simple PR, nothing impressive. Anyone could have done it.',
        distortionLabels: ['disqualifying_positive', 'magnification'],
        distortionConfidences: [0.87, 0.73],
        reframeText:
            'Positive feedback is valid, regardless of how "simple" you think the task was. Your expertise and attention to detail contributed to a good outcome. Accept the compliment.',
        explanation:
            'Disqualifying the positive dismisses good things as not counting. Magnification exaggerates the simplicity of your work while minimizing your contribution.',
        techniques: [
          'Gratitude Journaling',
          'Positive Data Log',
          'Cognitive Restructuring',
        ],
        createdAt: now.subtract(const Duration(days: 4, hours: 10)),
      ),
      JournalEntry(
        id: _uuid.v4(),
        text:
            'Took a walk in the park after work. The weather was nice and I felt calm for the first time this week. Small moments like these matter.',
        distortionLabels: [],
        distortionConfidences: [],
        reframeText: null,
        explanation: null,
        techniques: null,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
    for (final entry in entries) {
      await box.put(entry.id, entry);
    }
    await settingsBox.put(_seedKey, true);
  }
  static List<Map<String, dynamic>> getMockMoodData() {
    final now = DateTime.now();
    return [
      {'day': 'Mon', 'mood': 3, 'date': now.subtract(const Duration(days: 6))},
      {'day': 'Tue', 'mood': 2, 'date': now.subtract(const Duration(days: 5))},
      {'day': 'Wed', 'mood': 4, 'date': now.subtract(const Duration(days: 4))},
      {'day': 'Thu', 'mood': 3, 'date': now.subtract(const Duration(days: 3))},
      {'day': 'Fri', 'mood': 2, 'date': now.subtract(const Duration(days: 2))},
      {'day': 'Sat', 'mood': 4, 'date': now.subtract(const Duration(days: 1))},
      {'day': 'Sun', 'mood': 5, 'date': now},
    ];
  }
  static String moodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }
  static String moodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Neutral';
    }
  }
  static Color moodColor(int mood) {
    switch (mood) {
      case 1:
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFFF9800);
      case 3:
        return const Color(0xFFFFCA28);
      case 4:
        return const Color(0xFF66BB6A);
      case 5:
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFFFFCA28);
    }
  }
}
