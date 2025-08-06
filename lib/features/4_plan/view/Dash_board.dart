import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_detail_screen_viewmodel.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_screen_viewmodel.dart';
import 'package:fyp_proj/features/4_plan/model/thumbnail.dart';
import 'package:fyp_proj/features/4_plan/view/plan_detail_screen.dart';
import 'package:fyp_proj/features/4_plan/view/plan_input.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

    @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlanScreenViewModel>(context, listen: false);

    return StreamBuilder<List<TravelThumbnail>>(
      // Use the stream from the ViewModel
      stream: viewModel.travelPlansStream,
      builder: (context, snapshot) {
        // While waiting for the first data, show a loading shimmer
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading(context);
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final plans = snapshot.data;
        if (plans == null || plans.isEmpty) {
          return _buildStartCreateScreen(context);
        }

        // If there are plans, display them
        return _buildExistingPlansScreen(plans, context);
      },
    );
  }
  // This is the new shimmer loading widget for the planning screen
  Widget _buildShimmerLoading(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Plans'),
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 5, // Display 5 shimmering placeholder cards
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.white, // The base color of the shimmer
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStartCreateScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://images.unsplash.com/photo-1500835556837-99ac94a94552?q=80&w=1887&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black45,
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome,
                    size: 64,
                    color: Colors.white
                    ),
                const SizedBox(height: 24),
                const Text(
                  'Craft Your\nPerfect Journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Let our AI design a personalized itinerary just for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const TripInputScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;
                          final tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Get Started'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingPlansScreen(List<TravelThumbnail> travelSteps, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Plans'),
      ),
      body: ListView.builder(
        itemCount: travelSteps.length,
        itemBuilder: (context, index) {
          final step = travelSteps[index];
          return _buildDestinationCard(step, context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const TripInputScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                final tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDestinationCard(TravelThumbnail step, BuildContext context) {
    final viewModel = Provider.of<PlanScreenViewModel>(context, listen: false);

    Widget trailingWidget;
    switch (step.status) {
      case 'completed':
        trailingWidget =
            const Icon(Icons.arrow_forward_ios, color: Colors.white);
        break;
      case 'processing':
      case 'pending':
        trailingWidget = const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        );
        break;
      case 'error':
        trailingWidget = const Icon(Icons.error_outline, color: Colors.red);
        break;
      default:
        trailingWidget = const Icon(Icons.help_outline, color: Colors.grey);
    }

    final bool isTappable = step.status == 'completed';
    return Card(
      color: Colors.blueGrey,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip
          .antiAlias,
      child: InkWell(
        onTap: isTappable
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => PlanDetailViewmodel(step.documentId),
                      child: TripDetails(documentId: step.documentId),
                    ),
                  ),
                );
              }
            : () {
                final message = step.status == 'error'
                    ? 'There was an error generating this plan.'
                    : 'Plan for ${step.city} is still being generated.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Delete Plan'),
                content: Text(
                    'Are you sure you want to delete the plan for ${step.city}? This action cannot be undone.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      viewModel.deletePlan(step.documentId);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // Background Image
            Container(
              height: 150, // Give the card a fixed height
              width: double.infinity,
              decoration: BoxDecoration(
                
              ),
            ),
            // Content laid over the image
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Takes minimum space
                      children: [
                        Text(
                          overflow: TextOverflow.ellipsis,
                          step.city,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created on: ${DateFormat.yMMMd().format(step.createdAt)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailingWidget,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}