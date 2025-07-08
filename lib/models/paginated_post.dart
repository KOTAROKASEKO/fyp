import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/models/post_model.dart';

class PaginatedPosts {
  final List<Post> posts;
  final DocumentSnapshot? lastDocument; // 次の読み込みの開始点

  PaginatedPosts({
    required this.posts,
    this.lastDocument,
  });
}