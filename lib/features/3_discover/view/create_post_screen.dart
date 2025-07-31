import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_proj/features/1_authentication/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/create_post_viewmodel.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  Future<bool> _onWillPop(BuildContext context, CreatePostViewModel viewModel) async {
    if (!viewModel.hasUnsavedChanges || viewModel.isPosting) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard post?'),
        content: const Text("If you go back now, you'll lose your post."),
        actions: <Widget>[
          TextButton(
            child: const Text('Keep editing'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
            onPressed: () {
              viewModel.clearDraft();
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:ChangeNotifierProvider(
      create: (_) => CreatePostViewModel(),
      child: Consumer<CreatePostViewModel>(
        builder: (context, viewModel, child) {
          return WillPopScope(
            onWillPop: () => _onWillPop(context, viewModel),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Create Post'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    if (await _onWillPop(context, viewModel)) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: viewModel.canSubmit
                          ? () async {
                              if (FirebaseAuth.instance.currentUser == null) {
                                showSignInModal(context);
                              } else {
                                final success = await viewModel.submitPost();
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Post failed. Please try again.')),
                                  );
                                }
                              }
                            }
                          : null,
                      child: viewModel.isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post'),
                    ),
                  )
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCaptionField(viewModel),
                          const SizedBox(height: 24),
                          _buildImageGrid(context, viewModel),
                           const SizedBox(height: 24),
                          _buildTagEditor(context, viewModel),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActionBar(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );}

  Widget _buildCaptionField(CreatePostViewModel viewModel) {
    return TextField(
      onChanged: (value) => viewModel.setCaption(value),
      decoration: const InputDecoration(
        hintText: 'Share your travel experiences...',
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 18),
      ),
      style: const TextStyle(fontSize: 18),
      maxLines: null, // Allows for multiline input
    );
  }

  Widget _buildImageGrid(BuildContext context, CreatePostViewModel viewModel) {
    return GridView.builder(
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
    );
  }

  Widget _buildTagEditor(BuildContext context, CreatePostViewModel viewModel) {
    final textController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // The text field for inputting new tags
        TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'e.g., adventure, food, relaxation',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  viewModel.addTag(textController.text);
                  textController.clear();
                }
              },
            )
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              viewModel.addTag(value);
              textController.clear();
            }
          },
        ),
        const SizedBox(height: 12),
        // A wrap widget to display the chips for added tags
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: viewModel.manualTags.map((tag) {
            return Chip(
              label: Text('#$tag'),
              onDeleted: () {
                viewModel.removeTag(tag);
              },
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              deleteIconColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

   Widget _buildBottomActionBar(CreatePostViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, size: 28),
            onPressed: () => viewModel.pickImages(),
            tooltip: 'Add images',
          ),
          // You could add other icons here, e.g., for location tagging
        ],
      ),
    );
  }
}