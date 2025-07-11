// lib/screens/plan_screen.dart

import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/view/plan_creation_screen.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Itinerary Planner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'AI Itinerary Generation will be here.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
                onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                    const PlanCreationView(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.ease;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                    );
                  },
                  ),
                );
              },
              icon: const Icon(Icons.bolt),
              label: const Text('Let AI suggest a trip!'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}