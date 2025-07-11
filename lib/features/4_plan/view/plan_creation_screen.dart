import 'package:flutter/material.dart';

class PlanCreationView extends StatefulWidget{
  const PlanCreationView({super.key});

  @override
  State<PlanCreationView> createState() => _PlanCreationViewState();
}

class _PlanCreationViewState extends State<PlanCreationView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Plan'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.create, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Plan creation functionality will be here.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}