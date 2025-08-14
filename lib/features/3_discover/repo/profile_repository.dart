import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/3_discover/model/user_profile_model.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _userProfileBoxName = 'userProfileBox';

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = userData.userId;
    if (userId == "") throw Exception("User not logged in");
    await _firestore.collection('users_prof').doc(userId).update(data);
  }

  Future<UserProfile> getUserProfile() async {
    final userId = userData.userId;

    final box = Hive.box<UserProfile>(_userProfileBoxName);

    try {
      final userDoc =
          await _firestore.collection('users_prof').doc(userId).get();
      final userData = userDoc.data();

      final postCountQuery = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      final postCount = postCountQuery.count ?? 0;

      final userProfile = UserProfile(
        uid: userId,
        displayName:
            userData?['displayName'] ??
                _auth.currentUser?.displayName ??
                'No Name',
        username: userData?['username'] ?? 'username',
        bio: userData?['bio'] ?? '',
        profileImageUrl: userData?['profileImageUrl'] ?? '',
        postCount: postCount,
      );

      await box.put(userId, userProfile);
      return userProfile;
    } catch (e) {
      print("Error fetching profile from Firestore: $e");
      final cachedProfile = box.get(userId);
      if (cachedProfile != null) return cachedProfile;
      throw Exception("Failed to load profile and no cache available.");
    }
  }

  Future<UserProfile?> getCachedUserProfile() async {
    final userId = userData.userId;
    if (userId == "") return null;
    final box = Hive.box<UserProfile>(_userProfileBoxName);
    return box.get(userId);
  }

  Future<List<Post>> getMyPosts(
      {DocumentSnapshot? lastDocument, int limit = 12}) async {
    final userId = userData.userId;
    if (userId == "") return [];

    Query query = _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) =>
            Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }
}