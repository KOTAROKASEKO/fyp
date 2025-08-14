import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fyp_proj/features/3_discover/model/user_profile_model.dart';
import 'package:fyp_proj/features/3_discover/repo/profile_repository.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  UserProfile _userProfile = UserProfile.empty();
  UserProfile get userProfile => _userProfile;

  List<Post> _myPosts = [];
  List<Post> get myPosts => _myPosts;
  final ImagePicker _picker = ImagePicker();

  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLoadingMorePosts = false;
  bool get isLoadingMorePosts => _isLoadingMorePosts;

  bool _hasMorePosts = true;

  Future<void> updateProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final File imageFile = File(image.path);
    _isLoading = true;
    notifyListeners();

    try {
      final imageUrl = await _uploadProfileImage(imageFile);
      await _repository.updateUserProfile({'profileImageUrl': imageUrl});
      // プロファイルを再読み込みしてUIを更新
      await loadProfile();
    } catch (e) {
      print("Error updating profile image: $e");
      // TODO: ユーザーにエラーを通知
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File> compressAndConvertToWebP(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.webp';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 88,
      format: CompressFormat.webp,
    );
    // resultがnullの場合を考慮
    if (result == null) {
      throw Exception("Image compression failed.");
    }
    return File(result.path);
  }

  Future<String> _uploadProfileImage(File file) async {
    final userId = _repository.getCurrentUserId();
    if (userId == null) throw Exception("User not logged in");

    final compressedFile = await compressAndConvertToWebP(file);
    final fileName = 'profile_images/$userId.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = ref.putFile(compressedFile);
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

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
      final newPosts =
          await _repository.getMyPosts(lastDocument: _lastDocument);

      if (newPosts.isNotEmpty) {
        final lastPostId = newPosts.last.id;
        _lastDocument =
            await FirebaseFirestore.instance.collection('posts').doc(lastPostId).get();
      }

      if (newPosts.length < 12) {
        _hasMorePosts = false;
      }

      _myPosts.addAll(newPosts);
    } catch (e) {
      print("Error fetching my posts: $e");
    } finally {
      _isLoadingMorePosts = false;
      notifyListeners();
    }
  }
}