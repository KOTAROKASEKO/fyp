// 4_plan/view/generating_screen.dart

import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/generating_viewModel.dart';
import 'package:provider/provider.dart';

class GeneratingScreen extends StatefulWidget {
  final String city;
  final String budget;
  final String request;

  const GeneratingScreen({
    super.key,
    required this.city,
    required this.budget,
    required this.request,
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
    );

    if (mounted) {
      if (documentId != null) {
        // SUCCESS: Pop all the way back to the PlanScreen
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Give the user clear feedback that the request was successful.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your plan for ${widget.city} is being generated...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // FAILURE: Show an error and navigate back.
        Navigator.of(context).pop(); // Pop the generating screen
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
              // Replace with a Lottie animation for a more modern feel
              // For now, we'll keep the CircularProgressIndicator
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