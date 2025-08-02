// lib/features/3_discover/viewmodel/discover_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/models/post_model.dart';

class DiscoverViewModel extends ChangeNotifier {
  final PostService _postService = PostService();

  List<Post> _allFetchedPosts = [];
  List<Post> _posts = [];
  SortOrder _sortOrder = SortOrder.byDate;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;

  List<Post> get posts => _posts;
  SortOrder get sortOrder => _sortOrder;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;

  String _searchQuery = '';

  DiscoverViewModel() {
    fetchInitialPosts();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _posts = _allFetchedPosts;
    } else {
      final query = _searchQuery.toLowerCase();
      _posts = _allFetchedPosts.where((post) {
        final captionMatch = post.caption.toLowerCase().contains(query);
        // Use the new allTags getter to search in both manual and auto tags
        final tagMatch = post.allTags.any((tag) => tag.toLowerCase().contains(query));
        return captionMatch || tagMatch;
      }).toList();
    }
    notifyListeners();
  }



  Future<void> fetchInitialPosts() async {
    _isLoading = true;
    _hasMorePosts = true;
    _lastDocument = null;
    notifyListeners();

    try {
      final result = await _postService.getPosts(sortOrder: _sortOrder);
      _allFetchedPosts = result.posts;
      _lastDocument = result.lastDocument;
      if (result.posts.length < 10) {
        _hasMorePosts = false;
      }
      _applyFilter(); // Apply current search query to the new list
    } catch (e) {
      print("Error fetching initial posts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // --- MODIFIED: fetchMorePosts to handle filtering ---
  
  Future<void> fetchMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _postService.getPosts(
        sortOrder: _sortOrder,
        lastDocument: _lastDocument,
      );
      _allFetchedPosts.addAll(result.posts);
      _lastDocument = result.lastDocument;
      if (result.posts.length < 10) {
        _hasMorePosts = false;
      }
      _applyFilter(); // Apply current search query to the updated list
    } catch (e) {
      print("Error fetching more posts: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // --- NEW: Methods to update filters and trigger refetch ---
    void applySearchQuery(String query) {
    _searchQuery = query;
    // No need to fetch from network again, just apply filter locally
    _applyFilter();
  }

  Future<void> setSortOrder(SortOrder newOrder) async {
    if (_sortOrder == newOrder) return;
    _sortOrder = newOrder;
    fetchInitialPosts(); // Refetch with the new sort order
  }

  // --- NEW METHODS ---

  // 投稿を削除する
  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      // UIから投稿を即座に削除
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
    } catch (e) {
      print("Error deleting post: $e");
      // TODO: ユーザーにエラーを通知
    }
  }

  // 投稿を通報する
  Future<void> reportPost(String postId) async {
    try {
      await _postService.reportPost(postId);
      // TODO: 成功したことをユーザーに通知 (例: SnackBar)
      print("Post reported: $postId");
    } catch (e) {
      print("Error reporting post: $e");
    }
  }

  // 投稿を保存する
    Future<void> savePost(String postId) async {
    // 1. UI上の投稿リストから、対象の投稿を探す
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) {
      // 万が一見つからなければ、何もせず処理を終了する
      return;
    }

    final post = _posts[postIndex];
    final originalSaveState = post.isSaved; // 失敗した場合に備え、元の状態を記憶しておく

    // 2. オプティミスティックUI：まずUIを即座に更新する
    post.isSaved = !post.isSaved; // 保存状態を反転させる
    notifyListeners(); // UIに変更を通知して再描画させる

    // 3. バックエンド処理：UIとは非同期で、実際のデータ保存処理を呼び出す
    try {
      await _postService.toggleSavePost(postId); // サービス層のメソッドを呼び出す
    } catch (e) {
      // 4. エラー処理とロールバック：バックエンド処理が失敗した場合
      print("Error saving post: $e");

      // ユーザー体験を損なわないよう、UIを元の状態に戻す
      post.isSaved = originalSaveState;
      notifyListeners(); // UIに変更を通知して再描画させる

      // TODO: ユーザーにエラーが発生したことをSnackBarなどで通知する
    }
  }

  void toggleLike(String postId) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isLiked = post.likedBy.contains(userData.userId);

    if (isLiked) {
      post.likeCount--;
      post.likedBy.remove(userData.userId);
    } else {
      post.likeCount++;
      post.likedBy.add(userData.userId);
    }

    notifyListeners(); // Update the UI immediately

    // Then, call the service to update the backend
    _postService.toggleLike(postId).catchError((e) {
      // If the backend update fails, revert the change and notify the user
      if (isLiked) {
        post.likeCount++;
        post.likedBy.add(userData.userId);
      } else {
        post.likeCount--;
        post.likedBy.remove(userData.userId);
      }
      notifyListeners();
      print("Error toggling like: $e");
      // Optionally, show a snackbar to the user about the failure
    });
  }
}