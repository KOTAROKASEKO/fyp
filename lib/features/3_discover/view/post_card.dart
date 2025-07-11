import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/view/comment_bottomsheet.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/discover_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // REMOVED: Unnecessary initState and local 'post' variable.
  // We will use 'widget.post' directly for clarity and efficiency.

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showOptionsBottomSheet(BuildContext context, DiscoverViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        // MODIFIED: Use widget.post directly
        final bool isMyPost = widget.post.userId == userData.userId;

        return SafeArea(
          child: Wrap(
            children: [
              if (isMyPost)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    // MODIFIED: Use widget.post directly
                    viewModel.deletePost(widget.post.id);
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    // MODIFIED: Use widget.post directly
                    viewModel.reportPost(widget.post.id);
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
                    // MODIFIED: Use widget.post directly
                    viewModel.savePost(widget.post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post has been saved.'))
                    );
                  },
                ),
              ]
            ],
          )
        );
      },
    );
  }

  @override
    Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewModel = context.watch<DiscoverViewModel>();

    // --- CLEANER LOGIC: Define content flags once. ---
    // This is more robust than checking for null.
    final post = widget.post;
    final bool hasImages = post.imageUrls.isNotEmpty;
    final bool hasCaption = post.caption.isNotEmpty;
    final bool isLiked = post.isLikedByCurrentUser;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. User Header (No change) ---
          _buildUserHeader(context, textTheme, viewModel),

          // --- 2. Main Content (Image or Text) ---
          _buildMainContent(context, hasImages, hasCaption, textTheme),

          // --- 3. Action Buttons (No change) ---
          _buildActionButtons(context, viewModel, isLiked),

          // --- 4. Footer (Likes, Caption for Image-Posts, Timestamp) ---
          _buildFooter(context, textTheme, hasImages, hasCaption),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, TextTheme textTheme, DiscoverViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.post.userProfileImageUrl.isNotEmpty
                ? NetworkImage(widget.post.userProfileImageUrl)
                : null,
            child: widget.post.userProfileImageUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.username,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                // TODO: The language pair from your screenshot (`CN -> ID`) would go here.
                // This requires adding a `languagePair` field to your `Post` model.
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showOptionsBottomSheet(context, viewModel), // This needs fixing if it's still there
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool hasImages, bool hasCaption, TextTheme textTheme) {
    if (hasImages) {
      // --- IMAGE POST ---
      return AspectRatio(
        aspectRatio: 1, // You might want to make this 4/3 or 16/9 for non-square images
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.post.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return Image.network(
                  widget.post.imageUrls[index],
                  fit: BoxFit.cover,
                  // loading and error builders are good to keep
                );
              },
            ),
            if (widget.post.imageUrls.length > 1)
              _buildPageIndicator(context),
          ],
        ),
      );
    } else if (hasCaption) {
      // --- TEXT-ONLY POST ---
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          widget.post.caption,
          style: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.4), // Larger font for text posts
        ),
      );
    }
    // If a post has neither image nor caption, show nothing.
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(BuildContext context, DiscoverViewModel viewModel, bool isLiked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null,
              size: 28,
            ),
            onPressed: () => viewModel.toggleLike(widget.post.id),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 28),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CommentBottomSheet(postId: widget.post.id),
            ),
          ),
          IconButton(
            icon: Icon(
              widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 28,
              color: widget.post.isSaved ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () => viewModel.savePost(widget.post.id),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, TextTheme textTheme, bool hasImages, bool hasCaption) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.post.likeCount} likes',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          // The caption is only shown here if there are images.
          // For text-only posts, it's already displayed in _buildMainContent.
          if (hasImages && hasCaption) ...[
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${widget.post.username} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: widget.post.caption),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            timeago.format(widget.post.timestamp.toDate()),
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),

          if (widget.post.manualTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6.0,
            runSpacing: 2.0,
            children: widget.post.manualTags.map((tag) => Chip(
              label: Text('#$tag', style: TextStyle(fontSize: 12)),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return Positioned(
      bottom: 8.0,
      child: Row(
        children: List.generate(widget.post.imageUrls.length, (index) {
          return Container(
            width: 7.0,
            height: 7.0,
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? Theme.of(context).primaryColor
                  : Colors.white.withOpacity(0.7),
            ),
          );
        }),
      ),
    );
  }
}