import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final String imageUrl;
  final String caption;
  final Timestamp timestamp;
  final Map<String, bool> likes; // Simple map to track likes, { userId: true }

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.imageUrl,
    required this.caption,
    required this.timestamp,
    required this.likes,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likes: Map<String, bool>.from(data['likes'] ?? {}),
    );
  }

  int get likeCount => likes.length;
  bool isLikedByUser() {
        return likes.containsKey(userData.userId);
    }
}