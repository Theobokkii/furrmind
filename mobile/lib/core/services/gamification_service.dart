import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/mood_entry.dart';
final gamificationProvider = Provider((ref) => GamificationService());
final userProfileProvider = FutureProvider((ref) => ref.watch(gamificationProvider).getProfile());
final todayMoodProvider = FutureProvider((ref) => ref.watch(gamificationProvider).getTodayMood());
final weeklyMoodsProvider = FutureProvider((ref) => ref.watch(gamificationProvider).getWeeklyMoods());
class GamificationService {
  static const String profileBoxName = 'user_profile_box';
  static const String moodBoxName = 'mood_entries_box';
  Future<Box<UserProfile>> _getProfileBox() async {
    if (!Hive.isBoxOpen(profileBoxName)) {
      return await Hive.openBox<UserProfile>(profileBoxName);
    }
    return Hive.box<UserProfile>(profileBoxName);
  }
  Future<Box<MoodEntry>> _getMoodBox() async {
    if (!Hive.isBoxOpen(moodBoxName)) {
      return await Hive.openBox<MoodEntry>(moodBoxName);
    }
    return Hive.box<MoodEntry>(moodBoxName);
  }
  Future<UserProfile> getProfile() async {
    final box = await _getProfileBox();
    if (box.isEmpty) {
      final profile = UserProfile(username: 'Explorer', avatarEmoji: '👤');
      await box.put('current', profile);
      return profile;
    }
    return box.get('current')!;
  }
  Future<void> updateProfile({String? username, String? avatarEmoji}) async {
    final box = await _getProfileBox();
    final profile = await getProfile();
    if (username != null) profile.username = username;
    if (avatarEmoji != null) profile.avatarEmoji = avatarEmoji;
    await box.put('current', profile);
  }
  int _calculateLevel(int points) {
    if (points < 50) return 1;
    if (points < 150) return 2;
    if (points < 300) return 3;
    if (points < 500) return 4;
    return 5;
  }
  Future<void> addPoints(int points, {String? reason}) async {
    final box = await _getProfileBox();
    final profile = await getProfile();
    profile.totalPoints += points;
    final newLevel = _calculateLevel(profile.totalPoints);
    if (newLevel > profile.currentLevel) {
      profile.currentLevel = newLevel;
    }
    final badges = List<String>.from(profile.unlockedBadges);
    if (profile.totalPoints >= 10 && !badges.contains('First Step')) {
      badges.add('First Step');
    }
    if (profile.currentLevel >= 3 && !badges.contains('Mindful Master')) {
      badges.add('Mindful Master');
    }
    profile.unlockedBadges = badges;
    await box.put('current', profile);
  }
  Future<void> logMood(int score) async {
    final box = await _getMoodBox();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final entry = MoodEntry(
      id: todayStr,
      moodScore: score,
      createdAt: now,
    );
    await box.put(todayStr, entry);
    await addPoints(5, reason: 'Daily Mood Tracking');
  }
  Future<MoodEntry?> getTodayMood() async {
    final box = await _getMoodBox();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    return box.get(todayStr);
  }
  Future<List<MoodEntry>> getWeeklyMoods() async {
    final box = await _getMoodBox();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return box.values
        .where((e) => e.createdAt.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
