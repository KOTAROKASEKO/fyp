import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/discover_viewmodel.dart';
import 'package:fyp_proj/features/5_profile/view/saved_posts_tab.dart';
import 'package:fyp_proj/features/5_profile/viremodel/profile_viewmodel.dart';
import 'package:fyp_proj/models/post_model.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.myPosts.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                viewModel.userProfile.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () { /* TODO: Open settings menu */ },
                ),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(child: _ProfileHeader(viewModel: viewModel)),
                ];
              },
              body: Column(
                children: [
                  const TabBar(
                    indicatorColor: Colors.black,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on_outlined)),
                      Tab(icon: Icon(Icons.bookmark_border_outlined)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _MyPostsGrid(),
                        ChangeNotifierProvider(
                          create: (_) => DiscoverViewModel(),
                          child: SavedPostsTab(),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileViewModel viewModel;
  const _ProfileHeader({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final profile = viewModel.userProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: profile.profileImageUrl.isNotEmpty
                    ? NetworkImage(profile.profileImageUrl)
                    : null,
                child: profile.profileImageUrl.isEmpty
                    ? Icon(Icons.person, size: 40, color: Colors.grey.shade600)
                    : null,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Posts", profile.postCount.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.displayName.isNotEmpty)
                Text(
                  profile.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 4),
              if (profile.bio.isNotEmpty)
                Text(
                  profile.bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: OutlinedButton(
            onPressed: () { /* TODO: Navigate to Edit Profile Screen */ },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Edit Profile'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _MyPostsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final posts = viewModel.myPosts;

    if (viewModel.isLoading && posts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
        return const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No Posts Yet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
            )
        );
    }
    
    return RefreshIndicator(
        onRefresh: () => viewModel.fetchMyPosts(isInitial: true),
        child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1.5,
          mainAxisSpacing: 1.5,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final Post post = posts[index];
          return Image.network(
            post.imageUrls.first,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              return progress == null
                  ? child
                  : Container(color: Colors.grey[200]);
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.grey[200]);
            },
          );
        },
      ),
    );
  }
}