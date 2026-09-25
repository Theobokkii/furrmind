import 'package:flutter/material.dart';

class MoodUtils {
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
