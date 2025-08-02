import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/view/comment_tile.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/models/comment_model.dart';
import 'package:provider/provider.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;

  const CommentBottomSheet({super.key, required this.postId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  final PostService _postService = PostService();

  void _submitComment() {
    if (_commentController.text.trim().isNotEmpty) {
      _postService.addComment(
        postId: widget.postId,
        text: _commentController.text.trim(),
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Making the sheet draggable and taking up 90% of the screen height
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Start at 70% of the screen
      minChildSize: 0.4, // Can be dragged down to 40%
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return SafeArea(
          child:Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Column(
            children: [
              // Handle for dragging
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              // The list of comments
              Expanded(
                child: StreamProvider<List<Comment>>.value(
                  value: _postService.getComments(widget.postId),
                  initialData: const [],
                  child: Consumer<List<Comment>>(
                    builder: (context, comments, child) {
                      if (comments.isEmpty) {
                        return const Center(child: Text('No comments yet.'));
                      }
                      // Use the scrollController from DraggableScrollableSheet
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          // We reuse the CommentTile we already built
                          return CommentTile(postId: widget.postId, comment: comment);
                        },
                      );
                    },
                  ),
                ),
              ),
              // The input field
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20))
                          )
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
        )
      );},
    );
  }
}