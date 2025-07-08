import 'package:flutter/material.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/post_service.dart';
import 'package:fyp_proj/features/3_discover/view/create_post_screen.dart';
import 'package:fyp_proj/features/3_discover/view/post_card.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/discover_viewmodel.dart';
import 'package:provider/provider.dart'; // Postモデルのため

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProviderでViewModelをUIツリーに提供
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

class _DiscoverViewState extends State<_DiscoverView> with AutomaticKeepAliveClientMixin { // 1. Add mixin
  @override
  bool get wantKeepAlive => true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) { // 終端の少し手前で発火
        context.read<DiscoverViewModel>().fetchMorePosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Consumerを使ってViewModelの変更を監視
    return Consumer<DiscoverViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Discover Goals'),
            centerTitle: false,
            actions: [
              // ソート順切り替えボタン
              PopupMenuButton<SortOrder>(
                icon: const Icon(Icons.sort),
                onSelected: (order) => viewModel.setSortOrder(order),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: SortOrder.byDate,
                    child: Text('Newest'),
                  ),
                  const PopupMenuItem(
                    value: SortOrder.byPopularity,
                    child: Text('Popular'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                onPressed: () {
                  // 投稿画面をモーダルで表示
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreatePostScreen(),
                      fullscreenDialog: true, // 下からスライドアップするような表示になる
                    ),
                  );
                },
              ),
            ],
          ),
           body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => viewModel.fetchInitialPosts(),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: viewModel.posts.length + (viewModel.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == viewModel.posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final post = viewModel.posts[index];
                      // THIS IS THE FIX: Replace the placeholder Text with the PostCard
                      return PostCard(post: post);
                    },
                  ),
                ),
        );
      },
    );
  }
}