import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/create_post_viewmodel.dart';
import 'dart:io';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  // --- NEW: 画面を離れる際の警告ダイアログ ---
  Future<bool> _onWillPop(BuildContext context, CreatePostViewModel viewModel) async {
    if (!viewModel.hasUnsavedChanges || viewModel.isPosting) {
      return true; // 保存されていない変更がなければ、そのまま閉じる
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard post?'),
        content: const Text("If you go back now, you'll lose your post."),
        actions: <Widget>[
          TextButton(
            child: const Text('Keep editing'),
            onPressed: () => Navigator.of(context).pop(false), // ダイアログを閉じる
          ),
          TextButton(
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
            onPressed: () {
              viewModel.clearDraft(); // 下書きをクリア
              Navigator.of(context).pop(true); // ダイアログを閉じ、画面も閉じる
            },
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostViewModel(),
      child: SafeArea(
        child:Consumer<CreatePostViewModel>(
        builder: (context, viewModel, child) {
          // --- MODIFIED: WillPopScopeで画面を抜ける操作を検知 ---
          return WillPopScope(
            onWillPop: () => _onWillPop(context, viewModel),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Create Post'),
                // --- MODIFIED: Closeボタンも onWillPop をトリガーするように変更 ---
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    if (await _onWillPop(context, viewModel)) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: viewModel.canSubmit
                        ? () async {
                            final success = await viewModel.submitPost();
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Post failed. Please try again.')),
                              );
                            }
                          }
                        : null,
                    child: viewModel.isPosting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Post'),
                  )
                ],
              ),
              // --- MODIFIED: UI全体をキーボード表示に対応させる ---
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (value) => viewModel.setCaption(value),
                            decoration: const InputDecoration(
                              hintText: 'Share your travel experiences!',
                              border: InputBorder.none,
                            ),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          // --- NEW: 選択された画像を表示するグリッド ---
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: viewModel.selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      viewModel.selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => viewModel.removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildTagEditor(context, viewModel),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // --- NEW: キーボードの上のギャラリーアイコン ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, size: 28),
                          onPressed: () => viewModel.pickImages(),
                        ),
                        // 他のアイコンもここに追加可能
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ));
  }

  Widget _buildTagEditor(BuildContext context, CreatePostViewModel viewModel) {
    final textController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The text field for inputting new tags
        TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Add tags (e.g., finance, crypto)',
            // You can add a border if you like
          ),
          onSubmitted: (value) {
            // Add the tag when the user presses 'done' on the keyboard
            viewModel.addTag(value);
            textController.clear();
          },
        ),
        const SizedBox(height: 8),
        // A wrap widget to display the chips for added tags
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: viewModel.manualTags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () {
                viewModel.removeTag(tag);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}