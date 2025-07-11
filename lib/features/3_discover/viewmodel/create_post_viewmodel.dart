import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostViewModel extends ChangeNotifier {
  final List<String> _manualTags = [];
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedImages = [];
  String _caption = '';
  bool _isPosting = false;
  bool _hasUnsavedChanges = false; // 下書き保存のフラグ

  // --- MODIFIED: ゲッターもリストを返すように変更 ---
  List<File> get selectedImages => _selectedImages;
  String get caption => _caption;
  bool get isPosting => _isPosting;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get canSubmit => (_caption.isNotEmpty || _selectedImages.isNotEmpty) && !_isPosting;
  List<String> get manualTags => _manualTags;

  

  void setCaption(String value) {
    _caption = value;
    _updateUnsavedChangesFlag();
  }

  void _updateUnsavedChangesFlag() {
    _hasUnsavedChanges = _selectedImages.isNotEmpty || _caption.isNotEmpty;
    notifyListeners();
  }

  Future<void> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      _updateUnsavedChangesFlag();
      notifyListeners();
    }
  }

  void addTag(String tag) {
    final formattedTag = tag.trim().toLowerCase();
    if (formattedTag.isNotEmpty && !_manualTags.contains(formattedTag)) {
      _manualTags.add(formattedTag);
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    _manualTags.remove(tag);
    notifyListeners();
  }
  
  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      _updateUnsavedChangesFlag();
      notifyListeners();
    }
  }

  Future<File> compressAndConvertToWebP(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.webp';

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

  Future<bool> submitPost() async {
    // --- MODIFIED: Use the new computed property for the guard clause ---
    if (!canSubmit) {
      return false;
    }
    
    _isPosting = true;
    notifyListeners();

    try {
      // Logic is the same: upload files if they exist, then create post.
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await uploadFiles(_selectedImages);
      }

      await _postService.createPost(
        caption: _caption,
        imageUrls: imageUrls,
        manualTags: _manualTags,
      );

  
      
      _hasUnsavedChanges = false;
      return true;
    } catch (e) {
      print("Post submission failed: $e");
      return false;
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }

  // --- MODIFIED: 複数ファイルをアップロードするロジック ---
  Future<List<String>> uploadFiles(List<File> files) async {
    List<String> imageUrls = [];
    for (var file in files) {
      final compressedFile = await compressAndConvertToWebP(file);
      final fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.webp';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(compressedFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  
  // --- NEW: 下書きをクリアするメソッド ---
  void clearDraft() {
    _selectedImages = [];
    _caption = '';
    _hasUnsavedChanges = false;
    notifyListeners();
  }
}