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
  int likeCount;
  List<String> likedBy;
  bool isSaved; // This should also be mutable for optimistic UI updates.
  

  // REMOVED: isLiked is redundant. It can be derived from likedBy.

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    this.caption='',
    this.imageUrls = const [],
    required this.timestamp,
    required this.likeCount,
    required this.likedBy,
    this.isSaved = false,
    required this.manualTags,
  });

  // --- NEW: A computed property is cleaner than a separate state field ---
  // This removes the need for the 'isLiked' field and prevents data-sync issues.
  bool get isLikedByCurrentUser {
    return likedBy.contains(userData.userId);
  }

  // The factory method is where the primary errors were.
  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {bool isSaved = false}) {
    final data = doc.data();
    if (data == null) {
      // Handle the case where the document data is null.
      throw Exception("Post data is null for document ${doc.id}");
    }

    // --- CRITICAL FIX ---
    // 1. Use the correct key 'imageUrls' (plural).
    // 2. Safely cast the data from Firestore (which is List<dynamic>) to List<String>.
    // 3. Provide a correct default value: an empty list `[]`.
    final List<String> imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final List<String> likedBy = List<String>.from(data['likedBy'] ?? []);

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      caption: data['caption'] ?? '',
      imageUrls: imageUrls, // Use the correctly parsed list.
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likeCount: data['likeCount'] ?? 0,
      likedBy: likedBy,
      isSaved: isSaved,
      manualTags: List<String>.from(data['tags'] ?? []),
    );
  }
}