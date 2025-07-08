// lib/features/3_discover/view/post_card.dart

import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/view/comment_bottomsheet.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart'; // ユーザーIDを取得するためにインポート
import 'package:fyp_proj/features/3_discover/viewmodel/discover_viewmodel.dart'; // ViewModelをインポート
import 'package:provider/provider.dart'; // Providerをインポート
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  // ボトムシートを表示するメソッド
  void _showOptionsBottomSheet(BuildContext context, DiscoverViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        // 投稿の所有者かどうかを判断
        final bool isMyPost = post.userId == userData.userId;

        return Wrap(
          children: [
            if (isMyPost)
              // 自分の投稿の場合：削除オプション
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(ctx).pop(); // ボトムシートを閉じる
                  viewModel.deletePost(post.id); // ViewModelのメソッドを呼び出す
                },
              )
            else ...[
              // 他人の投稿の場合：通報と保存オプション
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  viewModel.reportPost(post.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post has been reported.'))
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Save'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  viewModel.savePost(post.id);
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post has been saved.'))
                  );
                },
              ),
            ]
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // ViewModelのインスタンスを取得
    final viewModel = context.watch<DiscoverViewModel>();
    // Determine if the post is liked by the current user
    final bool isLiked = post.likedBy.contains(userData.userId);


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.userProfileImageUrl.isNotEmpty
                      ? NetworkImage(post.userProfileImageUrl)
                      : null,
                  child: post.userProfileImageUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    post.username,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // TODO: Implement more options (e.g., report, delete)
                    _showOptionsBottomSheet(context, viewModel); // 修正：ボトムシートを表示
                  },
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 48)),
                );
              },
              ),
            ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                    size: 28,
                  ),
                  onPressed: () {
                    viewModel.toggleLike(post.id);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 28),
                   onPressed: () {
              // THIS IS THE NEW IMPLEMENTATION
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // IMPORTANT: Allows the sheet to resize for the keyboard
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return CommentBottomSheet(postId: post.id);
                },
              );
            },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post.likeCount} likes',
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: textTheme.bodyLarge,
                    children: [
                      TextSpan(
                        text: '${post.username} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                 Text(
                  timeago.format(post.timestamp.toDate()),
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}