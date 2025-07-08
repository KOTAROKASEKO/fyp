import 'package:flutter/material.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header: Profile Image & Username
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  // You can use a placeholder or the actual user profile image
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
                  },
                ),
              ],
            ),
          ),

          // 2. Post Image
            ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1, // 正方形
              child: Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              // 高さはAspectRatioで制御
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
            // 3. Action Buttons: Like, Comment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_outline, size: 28),
                  // TODO: Implement like functionality
                  onPressed: () {}, 
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 28),
                  // TODO: Implement comment functionality
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // 4. Caption and Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: Implement like count display
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