// lib/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final String caption;
  final List<String> imageUrls;
  final Timestamp timestamp;
  final List<String> manualTags;
  final List<String> autoTags; // NEW: Add autoTags
  int likeCount;
  List<String> likedBy;
  bool isSaved;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    this.caption = '',
    this.imageUrls = const [],
    required this.timestamp,
    required this.likeCount,
    required this.likedBy,
    this.isSaved = false,
    required this.manualTags,
    required this.autoTags, // NEW: Add to constructor
  });

  bool get isLikedByCurrentUser {
    return likedBy.contains(userData.userId);
  }

  // NEW: A helper to get all tags combined
  List<String> get allTags => [...manualTags, ...autoTags];

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {bool isSaved = false}) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Post data is null for document ${doc.id}");
    }

    final List<String> imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
    // MODIFIED: Correctly parse manualTags and add AutoTags
    final List<String> manualTags = List<String>.from(data['manualTags'] ?? []);
    final List<String> autoTags = List<String>.from(data['AutoTags'] ?? []);

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      caption: data['caption'] ?? '',
      imageUrls: imageUrls,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likeCount: data['likeCount'] ?? 0,
      likedBy: likedBy,
      isSaved: isSaved,
      manualTags: manualTags, // Use the parsed manualTags
      autoTags: autoTags,     // Use the parsed autoTags
    );
  }
}