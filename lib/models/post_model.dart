// models/post_model.dart (Assumed file)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final String caption;
  final String imageUrl;
  final Timestamp timestamp;
  int likeCount; // Changed to non-final
  List<String> likedBy; // List of user IDs who liked the post
  bool isLiked; // Client-side flag to show if the current user liked it

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.caption,
    required this.imageUrl,
    required this.timestamp,
    required this.likeCount,
    required this.likedBy,
    this.isLiked = false,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final List<String> likedBy = List<String>.from(data['likedBy'] ?? []);
    final String currentUserId = userData.userId;

    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likeCount: data['likeCount'] ?? 0,
      likedBy: likedBy,
      // Check if the current user's ID is in the list
      isLiked: likedBy.contains(currentUserId),
    );
  }
}