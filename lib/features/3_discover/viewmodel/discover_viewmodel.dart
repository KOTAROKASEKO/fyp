import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/core/service/post_service.dart';
import 'package:fyp_proj/models/post_model.dart';

class DiscoverViewModel extends ChangeNotifier {
  final PostService _postService = PostService();

  // --- State ---
  List<Post> _posts = [];
  SortOrder _sortOrder = SortOrder.byDate;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;

  // --- Getters for UI ---
  List<Post> get posts => _posts;
  SortOrder get sortOrder => _sortOrder;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;

  DiscoverViewModel() {
    // ViewModelが初期化されたら、最初の投稿リストを取得
    fetchInitialPosts();
  }

  // --- Actions ---

  // 初回の投稿リスト取得
  Future<void> fetchInitialPosts() async {
    _isLoading = true;
    _hasMorePosts = true;
    _lastDocument = null; // リストをリフレッシュ
    notifyListeners();

    try {
      final result = await _postService.getPosts(sortOrder: _sortOrder);
      _posts = result.posts;
      _lastDocument = result.lastDocument;
      if (result.posts.length < 10) { // 取得件数がlimitより少なければ、もう次はない
        _hasMorePosts = false;
      }
    } catch (e) {
      print("Error fetching initial posts: $e");
      // TODO: エラー状態をUIに伝える
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 追加の投稿を読み込む (ページネーション)
  Future<void> fetchMorePosts() async {
    // 既に読み込み中、またはこれ以上投稿がない場合は何もしない
    if (_isLoadingMore || !_hasMorePosts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _postService.getPosts(
        sortOrder: _sortOrder,
        lastDocument: _lastDocument,
      );
      _posts.addAll(result.posts); // 既存のリストに追加
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

  // ソート順を変更し、リストをリフレッシュする
  Future<void> setSortOrder(SortOrder newOrder) async {
    if (_sortOrder == newOrder) return; // 同じ順なら何もしない

    _sortOrder = newOrder;
    // 投稿リストをリセットして、新しい順序で最初から取得
    fetchInitialPosts();
  }
}