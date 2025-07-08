import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp_proj/features/3_discover/viewmodel/create_post_viewmodel.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Consumer<CreatePostViewModel>(
              builder: (context, viewModel, child) {
                return TextButton(
                  onPressed: viewModel.isPosting
                      ? null
                      : () async {
                          final success = await viewModel.submitPost();
                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post failed. Please try again.')),
                            );
                          }
                        },
                  child: viewModel.isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                );
              },
            )
          ],
        ),
        body: Consumer<CreatePostViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => viewModel.pickImage(),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: viewModel.selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                viewModel.selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to select an image'),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    onChanged: (value) => viewModel.setCaption(value),
                    decoration: const InputDecoration(
                      hintText: 'Write a caption...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}