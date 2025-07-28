import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_detail_screen_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // url_launcherをインポート
import 'package:fyp_proj/features/4_plan/model/plan_model.dart'; // TravelStepモデルをインポート

class TripDetails extends StatelessWidget {
  final String documentId;
  const TripDetails({super.key, required this.documentId});

  // --- 👇 これが最終版のメソッドです ---
  Future<void> _launchMaps(BuildContext context, TravelStep? origin, TravelStep destination) async {
    final Uri mapUri;

    // Google MapsがモバイルOSで確実に認識できる、標準的なウェブURLを組み立てます
    if (origin != null) {
      // 出発地と目的地がある場合 (経路案内)
      // https://www.google.com/maps/dir/?api=1&origin=...&destination=...
      mapUri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'origin': '${origin.location.latitude},${origin.location.longitude}',
        'destination': '${destination.location.latitude},${destination.location.longitude}'
      });
    } else {
      // 目的地のみの場合 (場所の検索・表示)
      // https://www.google.com/maps/search/?api=1&query=...&query_place_id=...
      mapUri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': destination.placeName, // 場所の名前で検索
        'query_place_id': destination.placeId // 場所IDで正確に指定
      });
    }

    // URLを起動できるか確認し、起動する
    try {
      if (await canLaunchUrl(mapUri)) {
        // 外部のネイティブアプリで開くように指定
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Itinerary'),
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
            return const Center(child: Text('No plan details available.'));
          }

          return ListView.builder(
            itemCount: viewModel.planSteps.length,
            itemBuilder: (context, index) {
              final step = viewModel.planSteps[index];
              return InkWell(
                onTap: () {
                  final origin = index > 0 ? viewModel.planSteps[index - 1] : null;
                  _launchMaps(context, origin, step);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${step.time} - ${step.placeName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.activityDescription,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'View on Map',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
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