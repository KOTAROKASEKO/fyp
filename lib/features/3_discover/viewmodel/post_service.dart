import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fyp_proj/debug/debug_print.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/models/comment_model.dart';
import 'package:fyp_proj/models/paginated_post.dart';
import 'package:fyp_proj/models/post_model.dart';

// ソート順を明確に定義するEnum
enum SortOrder { byDate, byPopularity }

class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Assuming you have FirebaseAuth instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'posts';
  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');
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
        'likedBy': [], // Initialize with an empty list
      });
    } catch (e) {
      print("Error creating post: $e");
      throw e;
    }
  }

  Future<void> toggleLike(String postId) async {
    final String userId = userData.userId;
    final DocumentReference postRef = _postsCollection.doc(postId);

    return _firestore.runTransaction((transaction) async {
      final DocumentSnapshot snapshot = await transaction.get(postRef);

      if (!snapshot.exists) {
        throw Exception("Post does not exist!");
      }

      // It's safer to cast to a list of strings.
      final List<String> likedBy = List<String>.from(snapshot.get('likedBy') ?? []);

      if (likedBy.contains(userId)) {
        // User has already liked the post, so unlike it
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId])
        });
      } else {
        // User has not liked the post, so like it
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId])
        });
      }
    });
  }

  Future<void> addComment({
    required String postId,
    required String text,
    String? parentCommentId, // Optional: for creating a reply
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';
      final userProfileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

      final commentData = {
        'text': text,
        'userId': user.uid,
        'username': username,
        'userProfileImageUrl': userProfileImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (parentCommentId != null) {
        // This is a reply
        await _postsCollection
            .doc(postId)
            .collection('comments')
            .doc(parentCommentId)
            .collection('replies')
            .add(commentData);
      } else {
        // This is a top-level comment
        await _postsCollection.doc(postId).collection('comments').add(commentData);
      }
    } catch (e) {
      print("Error adding comment: $e");
      throw e;
    }
  }

  // MODIFIED: Fetches only top-level comments
  Stream<List<Comment>> getComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  // NEW: Fetches replies for a specific comment
  Stream<List<Comment>> getReplies(String postId, String commentId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  deletePost(String postId) {}

  reportPost(String postId) {}

  savePost(String postId) {}
}