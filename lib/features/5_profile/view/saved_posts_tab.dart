import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/view/post_card.dart'; // Import PostCard
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedPostsTab extends StatefulWidget {
  const SavedPostsTab({super.key});

  @override
  _SavedPostsTabState createState() => _SavedPostsTabState();
}

class _SavedPostsTabState extends State<SavedPostsTab> {
  final PostService _postService = PostService();
  late Future<List<Post>> _savedPostsFuture;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _savedPostsFuture = _postService.getSavedPosts(userId);
    } else {
      _savedPostsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _savedPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading saved posts.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_remove, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Saved Posts',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Posts you save will appear here.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final savedPosts = snapshot.data!;

        // Replace GridView.builder with ListView.builder
        return ListView.builder(
          itemCount: savedPosts.length,
          itemBuilder: (context, index) {
            final post = savedPosts[index];
            // Render the full PostCard widget
            return PostCard(post: post);
          },
        );
      },
    );
  }
}