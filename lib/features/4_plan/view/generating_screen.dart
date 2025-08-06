import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/generating_viewModel.dart';
import 'package:provider/provider.dart';

class GeneratingScreen extends StatefulWidget {
  final String city;
  final String budget;
  final String request;
  final String fcmToken; // Add fcmToken

  const GeneratingScreen({
    super.key,
    required this.city,
    required this.budget,
    required this.request,
    required this.fcmToken, // Add to constructor
  });

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerPlanGeneration();
    });
  }

  Future<void> _triggerPlanGeneration() async {
    final viewModel = Provider.of<GeneratingViewModel>(context, listen: false);

    final documentId = await viewModel.createTravelRequest(
      city: widget.city,
      budget: widget.budget,
      request: widget.request,
      fcmToken: widget.fcmToken, // Pass token to ViewModel
    );

    if (mounted) {
      if (documentId != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your plan for ${widget.city} is being generated...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create a travel request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 5),
              const SizedBox(height: 32),
              Text(
                'Crafting your ${widget.city} adventure!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our AI is analyzing the best spots based on your preferences...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}