import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_detail_screen_viewmodel.dart';
import 'package:provider/provider.dart';

class TripDetails extends StatelessWidget {
  final String documentId; // このIDはデバッグや識別のために残しておいても良い
  const TripDetails({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    // `watch`を使ってViewModelの状態を監視する
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (viewModel.planSteps.isEmpty) {
            return const Center(child: Text('No plan details available.'));
          }

          // データが正常に取得できたらリスト表示
          return ListView.builder(
            itemCount: viewModel.planSteps.length,
            itemBuilder: (context, index) {
              final step = viewModel.planSteps[index];
              return Card(
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