import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gamification_service.dart';

class EmotionDefinition {
  final String id;
  final String label;
  final String emoji;
  final int valence;
  final int arousal;

  const EmotionDefinition({
    required this.id,
    required this.label,
    required this.emoji,
    required this.valence,
    required this.arousal,
  });
}

const List<EmotionDefinition> kBasicEmotions = [
  EmotionDefinition(id: 'joy', label: 'Joy', emoji: '😊', valence: 2, arousal: 2),
  EmotionDefinition(id: 'calm', label: 'Calm', emoji: '😌', valence: 1, arousal: -2),
  EmotionDefinition(id: 'hope', label: 'Hope', emoji: '🌱', valence: 2, arousal: 1),
  EmotionDefinition(id: 'gratitude', label: 'Gratitude', emoji: '🙏', valence: 2, arousal: -1),
  EmotionDefinition(id: 'sadness', label: 'Sadness', emoji: '😢', valence: -2, arousal: -1),
  EmotionDefinition(id: 'anxiety', label: 'Anxiety', emoji: '😰', valence: -2, arousal: 2),
  EmotionDefinition(id: 'anger', label: 'Anger', emoji: '😠', valence: -2, arousal: 2),
  EmotionDefinition(id: 'frustration', label: 'Frustration', emoji: '😤', valence: -1, arousal: 1),
  EmotionDefinition(id: 'loneliness', label: 'Loneliness', emoji: '🥺', valence: -2, arousal: -1),
  EmotionDefinition(id: 'confusion', label: 'Confusion', emoji: '😕', valence: -1, arousal: 1),
];

class MoodCheckIn {
  final EmotionDefinition primaryEmotion;
  final int intensity;
  final List<EmotionDefinition> secondaryEmotions;
  final List<String> contextTags;
  final String note;
  final DateTime createdAt;
  final double valence;
  final double arousal;

  MoodCheckIn({
    required this.primaryEmotion,
    required this.intensity,
    required this.secondaryEmotions,
    required this.contextTags,
    required this.note,
    required this.createdAt,
    required this.valence,
    required this.arousal,
  });
}

class MoodService {
  Future<MoodCheckIn> saveMoodCheckIn({
    required EmotionDefinition primary,
    required int intensity,
    required List<EmotionDefinition> secondary,
    required List<String> contextTags,
    required String note,
    required GamificationService gamification,
  }) async {
    // Non-clinical scoring
    double valence = primary.valence * intensity.toDouble();
    double arousal = primary.arousal * intensity.toDouble();

    for (final sec in secondary) {
      valence += sec.valence * 0.5;
      arousal += sec.arousal * 0.5;
    }

    final entry = MoodCheckIn(
      primaryEmotion: primary,
      intensity: intensity,
      secondaryEmotions: secondary,
      contextTags: contextTags,
      note: note,
      createdAt: DateTime.now(),
      valence: valence,
      arousal: arousal,
    );

    // Give XP (10 for standard, 2 for micro)
    await gamification.addPoints(10, reason: 'Daily Mood Check-in');
    
    // Log the mood score for the dashboard
    // Valence is -2 to 2. Map to 1 to 5.
    int score = primary.valence + 3;
    if (score < 1) score = 1;
    if (score > 5) score = 5;
    await gamification.logMood(score);

    return entry;
  }
}

final moodServiceProvider = Provider((ref) => MoodService());
