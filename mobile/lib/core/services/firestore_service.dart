import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService(this._firestore, this._auth);

  String? get currentUserId => _auth.currentUser?.uid;

  // --- USER PROFILE ---
  Future<void> saveUserProfile(UserProfile profile) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('users').doc(currentUserId).set({
      'username': profile.username,
      'avatarEmoji': profile.avatarEmoji,
      'totalPoints': profile.totalPoints,
      'currentLevel': profile.currentLevel,
      'unlockedBadges': profile.unlockedBadges,
      'pronouns': profile.pronouns,
      'bio': profile.bio,
      'friendIds': profile.friendIds,
      'bannerUrl': profile.bannerUrl,
      'activeTheme': profile.activeTheme,
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return UserProfile(
      username: data['username'] ?? '',
      avatarEmoji: data['avatarEmoji'] ?? '🐱',
      totalPoints: data['totalPoints'] ?? 0,
      currentLevel: data['currentLevel'] ?? 1,
      unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
      pronouns: data['pronouns'] ?? '',
      bio: data['bio'] ?? '',
      friendIds: List<String>.from(data['friendIds'] ?? []),
      bannerUrl: data['bannerUrl'] ?? 'default',
      activeTheme: data['activeTheme'] ?? 'default',
    );
  }

  Stream<UserProfile?> getUserProfileStream() {
    if (currentUserId == null) return Stream.value(null);
    return _firestore.collection('users').doc(currentUserId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return UserProfile(
        username: data['username'] ?? '',
        avatarEmoji: data['avatarEmoji'] ?? '🐱',
        totalPoints: data['totalPoints'] ?? 0,
        currentLevel: data['currentLevel'] ?? 1,
        unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
        pronouns: data['pronouns'] ?? '',
        bio: data['bio'] ?? '',
        friendIds: List<String>.from(data['friendIds'] ?? []),
        bannerUrl: data['bannerUrl'] ?? 'default',
        activeTheme: data['activeTheme'] ?? 'default',
      );
    });
  }

  // --- JOURNAL ENTRIES ---
  Future<void> saveJournalEntry(JournalEntry entry) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('journals')
        .doc(entry.id)
        .set({
      'id': entry.id,
      'text': entry.text,
      'createdAt': entry.createdAt.toIso8601String(),
      'distortionLabels': entry.distortionLabels,
      'distortionConfidences': entry.distortionConfidences,
      'reframeText': entry.reframeText,
      'explanation': entry.explanation,
      'techniques': entry.techniques,
    });
  }

  Stream<List<JournalEntry>> getJournalsStream() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('journals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return JournalEntry(
                id: data['id'],
                text: data['text'] ?? '',
                distortionLabels: List<String>.from(data['distortionLabels'] ?? []),
                distortionConfidences: List<double>.from(data['distortionConfidences']?.map((x) => (x as num).toDouble()) ?? []),
                reframeText: data['reframeText'],
                explanation: data['explanation'],
                techniques: data['techniques'] != null ? List<String>.from(data['techniques']) : null,
                createdAt: DateTime.parse(data['createdAt']),
              );
            }).toList());
  }

  Future<void> deleteJournalEntry(String id) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('journals')
        .doc(id)
        .delete();
  }

  // --- MOOD ENTRIES ---
  Future<void> saveMoodEntry(MoodEntry entry) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('moods')
        .doc(entry.id)
        .set({
      'id': entry.id,
      'moodScore': entry.moodScore,
      'createdAt': entry.createdAt.toIso8601String(),
    });
  }

  Stream<List<MoodEntry>> getMoodsStream() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('moods')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return MoodEntry(
                id: data['id'],
                moodScore: data['moodScore'] ?? 3,
                createdAt: DateTime.parse(data['createdAt']),
              );
            }).toList());
  }

  // --- SEARCH FRIENDS ---
  Future<List<Map<String, dynamic>>> searchUsersByUsername(String query) async {
    if (query.isEmpty) return [];
    
    // Firestore simple substring search trick using >= and <=
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '${query}z')
        .get();
        
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }
}
