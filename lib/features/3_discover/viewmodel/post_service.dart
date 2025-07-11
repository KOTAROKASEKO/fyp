import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  

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

  Future<List<Post>> getSavedPosts(String userId) async {
    try {
      // 1. Get the IDs of all saved posts.
      final savedPostsSnapshot =
          await _usersCollection.doc(userId).collection('savedPosts').get();

      if (savedPostsSnapshot.docs.isEmpty) {
        return []; // The user has no saved posts.
      }

      final savedPostIds = savedPostsSnapshot.docs.map((doc) => doc.id).toList();

      // 2. Fetch the actual post documents for those IDs.
      // Firestore's 'in' query is efficient for up to 10 items.
      // For simplicity, we'll fetch all at once. For >10, you might need batching.
      final postsSnapshot = await _postsCollection
          .where(FieldPath.documentId, whereIn: savedPostIds)
          .get();

      // Convert the documents to Post objects.
      // All posts here are considered "saved".
      final savedPosts = postsSnapshot.docs
          .map((doc) => Post.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              isSaved: true))
          .toList();

      return savedPosts;
    } catch (e) {
      print("Error fetching saved posts: $e");
      return [];
    }
  }

  Future<void> createPost({
    required String caption,
    required List<String> imageUrls, //
    required List<String> manualTags
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';
      final userProfileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

      await _firestore.collection('posts').add({
        'caption': caption,
        'imageUrls': imageUrls, // --- MODIFIED: imageUrlsをリストで保存 ---
        'userId': user.uid,
        'username': username,
        'userProfileImageUrl': userProfileImageUrl,
        'likeCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'likedBy': [],
        'manualTags': manualTags,
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

  deletePost(String postId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User is not logged in.");
    }

    // 1. Define the precise location of our target document.
    // This path is posts/{postId}.
    final postRef = _postsCollection.doc(postId);

    // 2. Check if the post exists.
    return postRef.get().then((doc) {
      if (!doc.exists) {
        throw Exception("Post does not exist.");
      }

      // 3. If it exists, delete the post.
      return postRef.delete();
    }).catchError((error) {
      print("Error deleting post: $error");
      throw error; // Re-throw to handle in the ViewModel
    });
  }

  reportPost(String postId) {}

 Future<void> toggleSavePost(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("User is not logged in.");
      }

      // 1. Define the precise location of our target document.
      // This path is users/{userId}/savedPosts/{postId}.
      // It's a direct link to the "bookmark" itself.
      final savedPostRef =
          _usersCollection.doc(userId).collection('savedPosts').doc(postId);

      // 2. Check for the document's existence.
      final doc = await savedPostRef.get();

      if (doc.exists) {
        // 3. If it exists, the post is currently saved.
        // The action is to UNSAVE it by deleting the document.
        await savedPostRef.delete();
      } else {
        // 4. If it does not exist, the post is not saved.
        // The action is to SAVE it by creating the document.
        // We store a timestamp for potential future features (e.g., sort by date saved).
        await savedPostRef.set({'timestamp': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      // 5. If any part of this process fails, we catch the error.
      print("Error toggling save state: $e");
      // Re-throw the exception so the ViewModel can catch it and handle the UI rollback.
      throw e;
    }
  }


}