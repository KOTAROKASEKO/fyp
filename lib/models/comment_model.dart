import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String text;
  final String userId;
  final String username;
  final String userProfileImageUrl;
  final Timestamp timestamp;

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.timestamp,
  });

  factory Comment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Comment(
      id: doc.id,
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}