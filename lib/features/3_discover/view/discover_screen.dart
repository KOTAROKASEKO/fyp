import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyp_proj/features/1_authentication/auth_service.dart';
import 'package:fyp_proj/features/3_discover/view/create_post_screen.dart';
import 'package:fyp_proj/features/3_discover/view/post_card.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/discover_viewmodel.dart';
import 'package:fyp_proj/features/3_discover/view/profilescreen.dart'; // ProfileScreenをインポート
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiscoverViewModel(),
      child: const _DiscoverView(),
    );
  }
}

class _DiscoverView extends StatefulWidget {
  const _DiscoverView();

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          context
              .read<DiscoverViewModel>()
              .applySearchQuery(_searchController.text);
        }
      });
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (mounted) {
          context.read<DiscoverViewModel>().fetchMorePosts();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewModel = context.watch<DiscoverViewModel>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search by caption or tag...',
              prefixIcon:
                  const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Colors.grey, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreatePostScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ],
        ),
        // --- NEW: Drawerウィジェットを追加 ---
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Log out'),
                onTap: () async {
                  Navigator.pop(context);
                  final bool? signedOut = await showSignOutModal(context);
                  if (signedOut == true) {
                    //reload the page if the user logged out
                    viewModel.fetchInitialPosts();
                  }
                },
              ),
            ],
          ),
        ),
        body: viewModel.isLoading
            ? _buildShimmerLoading()
            : RefreshIndicator(
                onRefresh: () => viewModel.fetchInitialPosts(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: viewModel.posts.length +
                      (viewModel.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (viewModel.posts.isEmpty && !viewModel.isLoadingMore) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("No posts found."),
                        ),
                      );
                    }
                    if (index == viewModel.posts.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final post = viewModel.posts[index];
                    return PostCard(post: post);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return const _ShimmerPostCard();
        },
      ),
    );
  }
}

class _ShimmerPostCard extends StatelessWidget {
  const _ShimmerPostCard();

  @override
  Widget build(BuildContext context) {
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
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 16, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.width - 8,
            width: double.infinity,
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity, height: 14, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 150, height: 14, color: Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }
}