import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_detail_screen_viewmodel.dart';
import 'package:fyp_proj/features/4_plan/view/quiz_generation_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fyp_proj/features/4_plan/model/plan_model.dart';

class TripDetails extends StatelessWidget {
  final String documentId;
  const TripDetails({super.key, required this.documentId});

  // --- Function to build Google Places Photo URL ---
  String? _getPhotoUrl(String? photoReference) {
    if (photoReference == null) return null;
    final apiKey = dotenv.env['Maps_api_key'] ?? '';
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
  }

  // --- NEW: Function to show a modal bottom sheet with step details ---
  void _showStepDetailsModal(BuildContext context, TravelStep step) {
    final imageUrl = _getPhotoUrl(step.photoReference);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Photo Display ---
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  // --- Details Padding ---
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.placeName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.time,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'How to Enjoy 🎉',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.activityDescription,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchMaps(BuildContext context, TravelStep? origin,
      TravelStep destination) async {
    final Uri mapUri;

    if (origin != null) {
      mapUri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'origin': '${origin.location.latitude},${origin.location.longitude}',
        'destination':
            '${destination.location.latitude},${destination.location.longitude}'
      });
    } else {
      mapUri = Uri.https('www.google.com', '/maps/search/',
          {'api': '1', 'query': destination.placeName});
    }

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $mapUri';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlanDetailViewmodel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Itinerary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
                child: Text(viewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red)));
          }

          if (viewModel.planSteps.isEmpty) {
            return const Center(child: Text('No plan details available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            itemCount: viewModel.planSteps.length,
            itemBuilder: (context, index) {
              final step = viewModel.planSteps[index];
              final origin = index > 0 ? viewModel.planSteps[index - 1] : null;
              final imageUrl = _getPhotoUrl(step.photoReference);

              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _showStepDetailsModal(context, step),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Image at the top of the card ---
                      if (imageUrl != null)
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              return progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.location_on,
                                    color: Colors.grey, size: 40),
                              );
                            },
                          ),
                        )
                      else
                        // --- Fallback if no image ---
                        Container(
                          height: 80,
                          color: colorScheme.secondaryContainer,
                          child: const Center(
                            child: Icon(Icons.location_on,
                                color: Colors.grey, size: 40),
                          ),
                        ),
                      // --- Text and actions content ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.time,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.placeName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: step.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.activityDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      // --- Action buttons bar ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  viewModel.toggleStepCompletion(index),
                              icon: Icon(
                                step.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: step.isCompleted
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              label: Text(
                                step.isCompleted ? 'Completed' : 'Mark as Done',
                                style: TextStyle(
                                    color: step.isCompleted
                                        ? Colors.green
                                        : Colors.grey),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.map_outlined,
                                      color: colorScheme.primary),
                                  onPressed: () =>
                                      _launchMaps(context, origin, step),
                                  tooltip: 'View on Map',
                                ),
                                IconButton(
                                  icon: Icon(Icons.quiz_outlined,
                                      color: colorScheme.secondary),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            QuizGenerationScreen(
                                                destination: step.placeName),
                                      ),
                                    );
                                  },
                                  tooltip: 'Test Your Knowledge',
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}