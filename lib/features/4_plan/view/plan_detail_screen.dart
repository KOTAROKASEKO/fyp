import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_detail_screen_viewmodel.dart';
import 'package:fyp_proj/features/4_plan/view/quiz_generation_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fyp_proj/features/4_plan/model/plan_model.dart';

class TripDetails extends StatelessWidget {
  final String documentId;
  const TripDetails({super.key, required this.documentId});

  Future<void> _launchMaps(BuildContext context, TravelStep? origin, TravelStep destination) async {
    final Uri mapUri;

    if (origin != null) {
      mapUri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'origin': '${origin.location.latitude},${origin.location.longitude}',
        'destination': '${destination.location.latitude},${destination.location.longitude}'
      });
    } else {
      mapUri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': destination.placeName,
        'query_place_id': destination.placeId
      });
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
            return Center(child: Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)));
          }

          if (viewModel.planSteps.isEmpty) {
            return const Center(
              child: Text('No plan details available.')
              );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: viewModel.planSteps.length,
            itemBuilder: (context, index) {
              final step = viewModel.planSteps[index];
              final origin = index > 0 ? viewModel.planSteps[index - 1] : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _launchMaps(context, origin, step),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      // ステータスインジケーター
                      Container(
                        width: 6,
                        height: 120, // カードの高さに応じて調整
                        decoration: BoxDecoration(
                          color: step.isCompleted ? Colors.green : colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  decoration: step.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.activityDescription,
                                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 完了ボタン
                                  TextButton.icon(
                                    onPressed: () => viewModel.toggleStepCompletion(index),
                                    icon: Icon(
                                      step.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: step.isCompleted ? Colors.green : Colors.grey,
                                    ),
                                    label: Text(
                                      step.isCompleted ? 'Completed' : 'Mark as Done',
                                      style: TextStyle(color: step.isCompleted ? Colors.green : Colors.grey),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  // アクションボタン
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.map_outlined, color: colorScheme.primary),
                                        onPressed: () => _launchMaps(context, origin, step),
                                        tooltip: 'View on Map',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.quiz_outlined, color: colorScheme.secondary),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => QuizGenerationScreen(destination: step.placeName),
                                            ),
                                          );
                                        },
                                        tooltip: 'Test Your Knowledge',
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
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