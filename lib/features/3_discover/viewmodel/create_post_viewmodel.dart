import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';


class CreatePostViewModel extends ChangeNotifier {
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String _caption = '';
  bool _isPosting = false;

  File? get selectedImage => _selectedImage;
  String get caption => _caption;
  bool get isPosting => _isPosting;

  void setCaption(String value) {
    _caption = value;
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _selectedImage = File(image.path);
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

    return File(result!.path);
  }

  Future<String> uploadFile(File file) async {
    final fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}.webp';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    return await snapshot.ref.getDownloadURL();
  }


  Future<bool> submitPost() async {
    if (_selectedImage == null || _caption.isEmpty || _isPosting) {
      return false;
    }

    _isPosting = true;
    notifyListeners();

    try {
      // 1. Compress and convert the image
      final compressedImage = await compressAndConvertToWebP(_selectedImage!);

      // 2. Upload to Firebase Storage
      final imageUrl = await uploadFile(compressedImage);

      // 3. Create the post with the new image URL
      await _postService.createPost(
        caption: _caption,
        imageUrl: imageUrl, // You'll need to update your PostService to accept an imageUrl
      );
      return true; // Success
    } catch (e) {
      print("Post submission failed: $e");
      return false; // Failure
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }
}