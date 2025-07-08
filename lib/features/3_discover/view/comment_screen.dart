import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/view/comment_tile.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/models/comment_model.dart';
import 'package:provider/provider.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _commentController = TextEditingController();
  final PostService _postService = PostService();

  void _submitComment() {
    if (_commentController.text.trim().isNotEmpty) {
      _postService.addComment(
        postId: widget.postId,
        text: _commentController.text.trim(),
      );
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamProvider<List<Comment>>.value(
              value: _postService.getComments(widget.postId),
              initialData: const [],
              child: Consumer<List<Comment>>(
                builder: (context, comments, child) {
                  if (comments.isEmpty) {
                    return const Center(child: Text('No comments yet. Be the first!'));
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return CommentTile(postId: widget.postId, comment: comment);
                    },
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}