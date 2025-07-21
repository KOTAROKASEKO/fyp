// 4_plan/view/plan_result_screen.dart
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/4_plan/model/plan_model.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlanResultScreen extends StatefulWidget {
  final String documentId;

  const PlanResultScreen({super.key, required this.documentId});

  @override
  State<PlanResultScreen> createState() => _PlanResultScreenState();
}

class _PlanResultScreenState extends State<PlanResultScreen> {
  @override
  Widget build(BuildContext context) {
    // This StreamBuilder listens to the specific document in Firestore.
    // Whenever the document changes, this widget will automatically rebuild.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('travelRequests')
          .doc(userData.userId)
          .collection('plans')
          .doc(widget.documentId)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatusScaffold("Connecting to your plan...");
        }

        // Handle errors
        if (snapshot.hasError) {
          return _buildStatusScaffold("Error loading plan.", isError: true);
        }

        // Handle case where document doesn't exist
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildStatusScaffold("Plan not found.", isError: true);
        }

        // Extract data and status from the document
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'] as String;

        // Display UI based on the status field
        switch (status) {
          case 'processing':
          case 'pending':
            return _buildStatusScaffold("Hold on tight, our AI is crafting the perfect itinerary for you...");
          case 'completed':
            // The plan is ready, parse it and display the list
            // In your StreamBuilder's 'completed' case:
          // Firestoreのフィールド名 'plan' に合わせる
          final List<dynamic> rawPlan = data['plan'] as List<dynamic>;

            // 2. TravelStepモデルのリストに変換する
            final List<TravelStep> completedPlan = rawPlan
                .map((stepData) => TravelStep.fromMap(stepData as Map<String, dynamic>))
                .toList();
                
            // 3. 型安全になったメソッドに、型安全なリストを渡す
            return _buildCompletedPlan(completedPlan);
          case 'error':
            final String errorMessage = data['errorMessage'] ?? 'An unknown error occurred.';
            return _buildStatusScaffold(errorMessage, isError: true);
          default:
            return _buildStatusScaffold("An unknown status was received.", isError: true);
        }
      },
    );
  }

  // A helper widget to show a loading/status screen
  Widget _buildStatusScaffold(String message, {bool isError = false}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isError ? 'Error' : 'Generating Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isError
                  ? Icon(Icons.error_outline, color: Colors.redAccent, size: 60)
                  : const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The main widget to display the completed itinerary
Widget _buildCompletedPlan(List<dynamic> plan) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Your AI-Generated Itinerary ✈️"),
    ),
    body: ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: plan.length,
      itemBuilder: (context, index) {
        final step = plan[index];
        final time = step.time;
        final placeName = step.placeName;
        final description = step.activityDescription;

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.25,
          isFirst: index == 0,
          isLast: index == plan.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 40,
            height: 40,
            indicator: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          beforeLineStyle: LineStyle(
            color: Theme.of(context).primaryColor,
            thickness: 2,
          ),
          endChild: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$time - $placeName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
}