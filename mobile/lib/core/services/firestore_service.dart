import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import 'auth_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  ref.watch(authStateChangesProvider);
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
      'name': profile.name,
      'username': profile.username,
      'avatarEmoji': profile.avatarEmoji,
      'totalPoints': profile.totalPoints,
      'currentLevel': profile.currentLevel,
      'unlockedBadges': profile.unlockedBadges,
      'pronouns': profile.pronouns,
      'bio': profile.bio,
      'friendIds': profile.friendIds,
      'pendingFriendRequests': profile.pendingFriendRequests,
      'sentFriendRequests': profile.sentFriendRequests,
      'bannerUrl': profile.bannerUrl,
      'activeTheme': profile.activeTheme,
    });
  }

  UserProfile _mapToUserProfile(Map<String, dynamic> data) {
    return UserProfile(
      name: data['name'] ?? data['username'] ?? '',
      username: data['username'] ?? '',
      avatarEmoji: data['avatarEmoji'] ?? '🐱',
      totalPoints: data['totalPoints'] ?? 0,
      currentLevel: data['currentLevel'] ?? 1,
      unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
      pronouns: data['pronouns'] ?? '',
      bio: data['bio'] ?? '',
      friendIds: List<String>.from(data['friendIds'] ?? []),
      pendingFriendRequests: List<String>.from(data['pendingFriendRequests'] ?? []),
      sentFriendRequests: List<String>.from(data['sentFriendRequests'] ?? []),
      bannerUrl: data['bannerUrl'] ?? 'default',
      activeTheme: data['activeTheme'] ?? 'default',
    );
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return _mapToUserProfile(doc.data()!);
  }

  Stream<UserProfile?> getUserProfileStream() {
    if (currentUserId == null) return Stream.value(null);
    return _firestore.collection('users').doc(currentUserId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _mapToUserProfile(doc.data()!);
    });
  }

  // --- FRIEND REQUESTS ---
  Future<void> sendFriendRequest(String targetUsername) async {
    if (currentUserId == null) return;
    final currentUser = await getUserProfile(currentUserId!);
    if (currentUser == null) return;
    
    final targetSnapshot = await _firestore.collection('users').where('username', isEqualTo: targetUsername).limit(1).get();
    if (targetSnapshot.docs.isEmpty) return;
    
    await targetSnapshot.docs.first.reference.update({
      'pendingFriendRequests': FieldValue.arrayUnion([currentUser.username])
    });
    
    await _firestore.collection('users').doc(currentUserId).update({
      'sentFriendRequests': FieldValue.arrayUnion([targetUsername])
    });
  }

  Future<void> acceptFriendRequest(String requesterUsername) async {
    if (currentUserId == null) return;
    final currentUser = await getUserProfile(currentUserId!);
    if (currentUser == null) return;
    
    final targetSnapshot = await _firestore.collection('users').where('username', isEqualTo: requesterUsername).limit(1).get();
    if (targetSnapshot.docs.isNotEmpty) {
      await targetSnapshot.docs.first.reference.update({
        'sentFriendRequests': FieldValue.arrayRemove([currentUser.username]),
        'friendIds': FieldValue.arrayUnion([currentUser.username])
      });
    }
    
    await _firestore.collection('users').doc(currentUserId).update({
      'pendingFriendRequests': FieldValue.arrayRemove([requesterUsername]),
      'friendIds': FieldValue.arrayUnion([requesterUsername])
    });
  }

  Future<void> declineFriendRequest(String requesterUsername) async {
    if (currentUserId == null) return;
    final currentUser = await getUserProfile(currentUserId!);
    if (currentUser == null) return;
    
    final targetSnapshot = await _firestore.collection('users').where('username', isEqualTo: requesterUsername).limit(1).get();
    if (targetSnapshot.docs.isNotEmpty) {
      await targetSnapshot.docs.first.reference.update({
        'sentFriendRequests': FieldValue.arrayRemove([currentUser.username]),
      });
    }
    
    await _firestore.collection('users').doc(currentUserId).update({
      'pendingFriendRequests': FieldValue.arrayRemove([requesterUsername]),
    });
  }

  Future<void> cancelFriendRequest(String targetUsername) async {
    if (currentUserId == null) return;
    final currentUser = await getUserProfile(currentUserId!);
    if (currentUser == null) return;
    
    final targetSnapshot = await _firestore.collection('users').where('username', isEqualTo: targetUsername).limit(1).get();
    if (targetSnapshot.docs.isNotEmpty) {
      await targetSnapshot.docs.first.reference.update({
        'pendingFriendRequests': FieldValue.arrayRemove([currentUser.username]),
      });
    }
    
    await _firestore.collection('users').doc(currentUserId).update({
      'sentFriendRequests': FieldValue.arrayRemove([targetUsername]),
    });
  }

  Future<void> removeFriend(String friendUsername) async {
    if (currentUserId == null) return;
    final currentUser = await getUserProfile(currentUserId!);
    if (currentUser == null) return;
    
    final targetSnapshot = await _firestore.collection('users').where('username', isEqualTo: friendUsername).limit(1).get();
    if (targetSnapshot.docs.isNotEmpty) {
      await targetSnapshot.docs.first.reference.update({
        'friendIds': FieldValue.arrayRemove([currentUser.username]),
      });
    }
    
    await _firestore.collection('users').doc(currentUserId).update({
      'friendIds': FieldValue.arrayRemove([friendUsername]),
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

  // --- SEARCH FRIENDS & SOCIAL ---
  Future<List<UserProfile>> searchUsersByUsername(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '${query}z')
        .get();
        
    return snapshot.docs.map((doc) => _mapToUserProfile(doc.data())).toList();
  }

  Future<List<UserProfile>> getDiscoverUsers(int limitCount) async {
    final snapshot = await _firestore.collection('users').limit(limitCount).get();
    return snapshot.docs
        .map((doc) => _mapToUserProfile(doc.data()))
        .where((u) => u.username.isNotEmpty)
        .toList();
  }

  Future<List<UserProfile>> getFriendsProfiles(List<String> friendUsernames) async {
    if (friendUsernames.isEmpty) return [];
    // For portfolio scale, fetching all and filtering in-memory is acceptable
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => _mapToUserProfile(doc.data()))
        .where((u) => friendUsernames.contains(u.username))
        .toList();
  }

  // --- CATO CHAT ---
  Future<void> saveChatMessage(String text, bool isUser) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cato_chats')
        .add({
      'text': text,
      'isUser': isUser,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> getChatMessagesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cato_chats')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'text': data['text'] ?? '',
                'isUser': data['isUser'] ?? false,
                'isCato': !(data['isUser'] ?? false),
              };
            }).toList());
  }

  // --- FRIEND CHAT (REALTIME) ---
  String _getChatRoomId(String user1, String user2) {
    final List<String> users = [user1, user2];
    users.sort();
    return '${users[0]}_${users[1]}';
  }

  Stream<List<Map<String, dynamic>>> getFriendChatMessagesStream(String currentUsername, String friendUsername) {
    final roomId = _getChatRoomId(currentUsername, friendUsername);
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendFriendMessage(String currentUsername, String friendUsername, String text) async {
    final roomId = _getChatRoomId(currentUsername, friendUsername);
    final chatRef = _firestore.collection('chats').doc(roomId);
    
    // Ensure room exists
    await chatRef.set({
      'participants': [currentUsername, friendUsername],
    }, SetOptions(merge: true));

    // Add message
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': currentUsername,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTypingStatus(String currentUsername, String friendUsername, bool isTyping) async {
    final roomId = _getChatRoomId(currentUsername, friendUsername);
    await _firestore.collection('chats').doc(roomId).set({
      'typing_$currentUsername': isTyping,
    }, SetOptions(merge: true));
  }

  Stream<bool> getTypingStatusStream(String currentUsername, String friendUsername) {
    final roomId = _getChatRoomId(currentUsername, friendUsername);
    return _firestore
        .collection('chats')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          if (data == null) return false;
          return data['typing_$friendUsername'] == true;
        });
  }
}
