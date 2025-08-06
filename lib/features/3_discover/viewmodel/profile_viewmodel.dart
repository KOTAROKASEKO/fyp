import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/model/user_profile_model.dart';
import 'package:fyp_proj/features/3_discover/repo/profile_repository.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  UserProfile _userProfile = UserProfile.empty();
  UserProfile get userProfile => _userProfile;

  List<Post> _myPosts = [];
  List<Post> get myPosts => _myPosts;

  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLoadingMorePosts = false;
  bool get isLoadingMorePosts => _isLoadingMorePosts;

  bool _hasMorePosts = true;

  ProfileViewModel() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    final cachedProfile = await _repository.getCachedUserProfile();
    if (cachedProfile != null) {
      _userProfile = cachedProfile;
      notifyListeners();
    }
    
    try {
      _userProfile = await _repository.getUserProfile();
      await fetchMyPosts(isInitial: true);
    } catch (e) {
      print("Error in ViewModel loading profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyPosts({bool isInitial = false}) async {
    if (_isLoadingMorePosts) return;
    
    if (isInitial) {
      _myPosts = [];
      _lastDocument = null;
      _hasMorePosts = true;
    }

    if (!_hasMorePosts) return;

    _isLoadingMorePosts = true;

    try {
      final postsQuery = await _repository.getMyPosts(lastDocument: _lastDocument);
      final newPosts = postsQuery;

      if (newPosts.isNotEmpty) {
        final lastPostId = newPosts.last.id;
        _lastDocument = await FirebaseFirestore.instance.collection('posts').doc(lastPostId).get();
      }
      
      if (newPosts.length < 12) {
        _hasMorePosts = false;
      }

      _myPosts.addAll(newPosts);
    } catch(e) {
      print("Error fetching my posts: $e");
    } finally {
      _isLoadingMorePosts = false;
      notifyListeners();
    }
  }
}