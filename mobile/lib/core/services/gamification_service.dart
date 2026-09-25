import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../models/mood_entry.dart';
import 'firestore_service.dart';

final gamificationProvider = Provider((ref) => GamificationService(ref));

final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserProfileStream().map((profile) => 
    profile ?? UserProfile(name: 'Explorer', username: 'explorer', avatarEmoji: '👤')
  );
});

final todayMoodProvider = StreamProvider<MoodEntry?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMoodsStream().map((moods) {
    final now = DateTime.now();
    try {
      return moods.firstWhere((e) => 
        e.createdAt.year == now.year && 
        e.createdAt.month == now.month && 
        e.createdAt.day == now.day
      );
    } catch (_) {
      return null;
    }
  });
});

final allMoodsProvider = StreamProvider<List<MoodEntry>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMoodsStream().map((moods) {
    moods.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return moods;
  });
});

class GamificationService {
  final Ref _ref;
  
  GamificationService(this._ref);

  Future<UserProfile> getProfile() async {
    final firestoreService = _ref.read(firestoreServiceProvider);
    final uid = firestoreService.currentUserId;
    if (uid == null) return UserProfile(name: 'Explorer', username: 'explorer', avatarEmoji: '👤');
    final profile = await firestoreService.getUserProfile(uid);
    return profile ?? UserProfile(name: 'Explorer', username: 'explorer', avatarEmoji: '👤');
  }

  Future<void> updateProfile({
    String? name,
    String? username, 
    String? avatarEmoji,
    String? pronouns,
    String? bio,
    List<String>? friendIds,
    String? bannerUrl,
    String? activeTheme,
  }) async {
    final firestoreService = _ref.read(firestoreServiceProvider);
    final profile = await getProfile();
    
    if (name != null) profile.name = name;
    if (username != null) profile.username = username;
    if (avatarEmoji != null) profile.avatarEmoji = avatarEmoji;
    if (pronouns != null) profile.pronouns = pronouns;
    if (bio != null) profile.bio = bio;
    if (friendIds != null) profile.friendIds = friendIds;
    if (bannerUrl != null) profile.bannerUrl = bannerUrl;
    if (activeTheme != null) profile.activeTheme = activeTheme;
    
    await firestoreService.saveUserProfile(profile);
  }

  int _calculateLevel(int points) {
    if (points < 50) return 1;
    if (points < 150) return 2;
    if (points < 300) return 3;
    if (points < 500) return 4;
    return 5;
  }

  Future<void> addPoints(int points, {String? reason}) async {
    final firestoreService = _ref.read(firestoreServiceProvider);
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
    
    await firestoreService.saveUserProfile(profile);
  }

  Future<void> logMood(int score) async {
    final firestoreService = _ref.read(firestoreServiceProvider);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    
    final entry = MoodEntry(
      id: todayStr,
      moodScore: score,
      createdAt: now,
    );
    
    await firestoreService.saveMoodEntry(entry);
    await addPoints(5, reason: 'Daily Mood Tracking');
  }
}
