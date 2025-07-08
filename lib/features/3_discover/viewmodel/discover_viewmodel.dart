// lib/features/3_discover/viewmodel/discover_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/models/post_model.dart';

class DiscoverViewModel extends ChangeNotifier {
  final PostService _postService = PostService();

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

  DiscoverViewModel() {
    fetchInitialPosts();
  }

  Future<void> fetchInitialPosts() async {
    _isLoading = true;
    _hasMorePosts = true;
    _lastDocument = null;
    notifyListeners();

    try {
      final result = await _postService.getPosts(sortOrder: _sortOrder);
      _posts = result.posts;
      _lastDocument = result.lastDocument;
      if (result.posts.length < 10) {
        _hasMorePosts = false;
      }
    } catch (e) {
      print("Error fetching initial posts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _postService.getPosts(
        sortOrder: _sortOrder,
        lastDocument: _lastDocument,
      );
      _posts.addAll(result.posts);
      _lastDocument = result.lastDocument;
      if (result.posts.length < 10) {
        _hasMorePosts = false;
      }
    } catch (e) {
      print("Error fetching more posts: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setSortOrder(SortOrder newOrder) async {
    if (_sortOrder == newOrder) return;

    _sortOrder = newOrder;
    fetchInitialPosts();
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
    try {
      await _postService.savePost(postId);
      // TODO: 成功したことをユーザーに通知
      print("Post saved: $postId");
    } catch (e) {
      print("Error saving post: $e");
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