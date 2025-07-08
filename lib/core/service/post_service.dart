import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fyp_proj/debug/debug_print.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/models/paginated_post.dart';
import 'package:fyp_proj/models/post_model.dart';

// ソート順を明確に定義するEnum
enum SortOrder { byDate, byPopularity }

class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Assuming you have FirebaseAuth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'posts';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<PaginatedPosts> getPosts({
    required SortOrder sortOrder,
    DocumentSnapshot? lastDocument,
    int limit = 10, // 1度に取得する投稿数
  }) async {
    // ベースとなるクエリを作成
    Query query = _firestore.collection(_collectionPath);

    // sortOrderに基づいてクエリを構築
    if (sortOrder == SortOrder.byPopularity) {
      // 重要: このクエリにはFirestoreの複合インデックスが必要です
      query = query.orderBy('likeCount', descending: true);
    } else {
      // デフォルトは日付順
      query = query.orderBy('timestamp', descending: true);
    }

    // ページネーション: lastDocumentが指定されていれば、その次から取得を開始
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    // 取得件数を制限
    query = query.limit(limit);

    final snapshot = await query.get();

    final posts = snapshot.docs
        .map((doc) => Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
    
    // 最後のドキュメントを取得（次回のクエリのため）
    final DocumentSnapshot? newLastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return PaginatedPosts(posts: posts, lastDocument: newLastDocument);
  }

  // ... (以前作成したtoggleLikeメソッド)
    // In your PostService class

Future<void> createPost({
  required String caption,
  required String imageUrl, // Changed from imageFile
}) async {
  try {
    final user = _auth.currentUser; // Assuming you have FirebaseAuth instance
    if (user == null) throw Exception("User not logged in");

    // Fetch user details (username, profile picture) from Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['username'] ?? 'Anonymous';
    final userProfileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

    await _firestore.collection('posts').add({
      'caption': caption,
      'imageUrl': imageUrl, // Use the URL from Firebase Storage
      'userId': user.uid,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'likeCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print("Error creating post: $e");
    throw e;
  }
}

  Future<void> toggleLike(String postId, bool isLiked) async {
        final String userId = userData.userId;
        if (userId.isEmpty) {
          throw Exception("User is not logged in.");
        }

        final postRef = _firestore.collection(_collectionPath).doc(postId);

        if (isLiked) {
          // Atomically remove the user's ID from the likes map
          await postRef.update({
            'likes.$userId': FieldValue.delete(),
          });
        } else {
          // Atomically add the user's ID to the likes map
          await postRef.update({
            'likes.$userId': true,
          });
        }
    }
}