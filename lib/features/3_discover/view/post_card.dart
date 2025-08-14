import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_proj/features/1_authentication/auth_service.dart';
import 'package:fyp_proj/features/3_discover/view/comment_bottomsheet.dart';
// Import the new animation widget you just created.
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/models/comment_model.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/discover_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Image; // Import the Rive package
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

  // Rive state management
  Artboard? _riveArtboard;
  SMIInput<bool>? _isLikedInput;

  @override
  void initState() {
    super.initState();
    // Load the Rive file and initialize the state machine
    rootBundle.load('assets/like.riv').then(
      (data) async {
        try {
          final file = RiveFile.import(data);
          final artboard = file.mainArtboard;
          // The state machine name must match your Rive file
          var controller =
              StateMachineController.fromArtboard(artboard, 'State Machine 1');
          if (controller != null) {
            artboard.addController(controller);
            // The input name must match your Rive file
            _isLikedInput = controller.findInput<bool>('isLiked');
            // Set the initial state of the animation
            _isLikedInput?.value = widget.post.isLikedByCurrentUser;
          }
          setState(() => _riveArtboard = artboard);
        } catch (e) {
          print(e);
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }



  void _showOptionsBottomSheet(
      BuildContext context, DiscoverViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
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
                    viewModel.deletePost(widget.post.id);
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    viewModel.reportPost(widget.post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post has been reported.')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_border),
                  title: const Text('Save'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    viewModel.savePost(widget.post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post has been saved.')));
                  },
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewModel = context.watch<DiscoverViewModel>();

    final post = widget.post;
    final bool hasImages = post.imageUrls.isNotEmpty;
    final bool hasCaption = post.caption.isNotEmpty;

    // Sync the Rive animation state with the data state on every build
    _isLikedInput?.value = post.isLikedByCurrentUser;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(context, textTheme, viewModel),
          GestureDetector(
            // MODIFIED: onDoubleTap callback
            onDoubleTap: () {
              if (FirebaseAuth.instance.currentUser == null) {
                showSignInModal(context);
                return;
              }
              viewModel.toggleLike(widget.post.id);
            },
            child: _buildMainContent(context, hasImages, hasCaption, textTheme),
          ),
          _buildActionButtons(context, viewModel),
          _buildFooter(context, textTheme, hasImages, hasCaption),
        ],
      ),
    );
  }

  Widget _buildUserHeader(
      BuildContext context, TextTheme textTheme, DiscoverViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.post.userProfileImageUrl.isNotEmpty
                ? NetworkImage(widget.post.userProfileImageUrl)
                : null,
            child: widget.post.userProfileImageUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.username,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showOptionsBottomSheet(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool hasImages,
      bool hasCaption, TextTheme textTheme) {
    if (hasImages) {
      return AspectRatio(
        aspectRatio: 1,
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
                );
              },
            ),
            if (widget.post.imageUrls.length > 1) _buildPageIndicator(context),
          ],
        ),
      );
    } else if (hasCaption) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          widget.post.caption,
          style: textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(
      BuildContext context, DiscoverViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (FirebaseAuth.instance.currentUser == null) {
                showSignInModal(context);
                return;
              }
              viewModel.toggleLike(widget.post.id);
            },
            child: SizedBox(
              width: 30,
              height: 30,
              child: _riveArtboard == null
                  // Show a placeholder while Rive is loading
                  ? const Center(child: Icon(Icons.favorite_border))
                  : Rive(
                      artboard: _riveArtboard!,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 28),
              onPressed: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showSignInModal(context);
                  return;
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        CommentBottomSheet(postId: widget.post.id),
                  );
                }
              }),
          IconButton(
            icon: Icon(
              widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 28,
              color:
                  widget.post.isSaved ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              if (FirebaseAuth.instance.currentUser == null) {
                showSignInModal(context);
                return;
              } else {
                viewModel.savePost(widget.post.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, TextTheme textTheme,
      bool hasImages, bool hasCaption) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.post.likeCount} likes',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
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
              children: widget.post.manualTags
                  .map((tag) => Chip(
                        label: Text('#$tag',
                            style: const TextStyle(fontSize: 12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          StreamBuilder<List<Comment>>(
            stream: PostService().getLatestComment(widget.post.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final latestComment = snapshot.data!.first;
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: GestureDetector(
                  onTap: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                      showSignInModal(context);
                      return;
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CommentBottomSheet(
                          postId: widget.post.id,
                        ),
                      );
                    }
                  },
                  child: Column(
                  crossAxisAlignment:  CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                    Text('Comment: '),
                    RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: '${latestComment.username} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: latestComment.text),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
                )
              );
            },
          ),
          
          
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