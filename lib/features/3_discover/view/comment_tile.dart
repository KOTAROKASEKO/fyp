import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/models/comment_model.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentTile extends StatefulWidget {
  final String postId;
  final Comment comment;
  final bool isReply; // To slightly change the UI for replies

  const CommentTile({
    super.key,
    required this.postId,
    required this.comment,
    this.isReply = false,
  });

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  final _replyController = TextEditingController();
  final PostService _postService = PostService();
  bool _isReplying = false;

  void _submitReply() {
    if (_replyController.text.trim().isEmpty) return;
    _postService.addComment(
      postId: widget.postId,
      text: _replyController.text.trim(),
      parentCommentId: widget.comment.id,
    );
    setState(() {
      _replyController.clear();
      _isReplying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(left: widget.isReply ? 30.0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.comment.userProfileImageUrl),
            ),
            title: RichText(
              text: TextSpan(
                style: textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${widget.comment.username} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: widget.comment.text),
                ],
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  timeago.format(widget.comment.timestamp.toDate()),
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(width: 12),
                if (!widget.isReply) // Don't allow replying to a reply
                  GestureDetector(
                    onTap: () => setState(() => _isReplying = !_isReplying),
                    child: Text(
                      'Reply',
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          if (_isReplying)
            Padding(
              padding: const EdgeInsets.only(left: 60, right: 16, bottom: 8),
              child: TextField(
                controller: _replyController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Reply to ${widget.comment.username}...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _submitReply,
                  ),
                ),
              ),
            ),
          // StreamBuilder for replies
          if (!widget.isReply)
            StreamProvider<List<Comment>>.value(
              value: _postService.getReplies(widget.postId, widget.comment.id),
              initialData: const [],
              child: Consumer<List<Comment>>(
                builder: (context, replies, child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      return CommentTile(
                        postId: widget.postId,
                        comment: replies[index],
                        isReply: true,
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}