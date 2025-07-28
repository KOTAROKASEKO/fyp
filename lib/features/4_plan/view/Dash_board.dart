import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_detail_screen_viewmodel.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_screen_viewmodel.dart';
import 'package:fyp_proj/features/4_plan/model/thumbnail.dart';
import 'package:fyp_proj/features/4_plan/view/plan_detail_screen.dart';
import 'package:fyp_proj/features/4_plan/view/plan_input.dart';
import 'package:provider/provider.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    PlanScreenViewModel viewModel = Provider.of<PlanScreenViewModel>(context);
    
    return viewModel.isLoading? 
    shimmerLoading() : 
    viewModel.hasData
    ?
    _buildExistingPlansScreen(viewModel.thumbnail, context):_buildStartCreateScreen(context);
    }

  Widget shimmerLoading(){
    return Scaffold(
      body:Center(child:CircularProgressIndicator()));
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
                    size: 64, color: Colors.white),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
        title: const Text('Plans'),
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

Widget _buildDestinationCard(TravelThumbnail step, BuildContext context){ // contextを引数で受け取る
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(step.city),
        subtitle: Text('Status: ${step.status}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              // ChangeNotifierProviderでViewModelを生成し、TripDetailsを子にする
              builder: (context) => ChangeNotifierProvider(
                create: (_) => PlanDetailViewmodel(step.documentId), // ここでIDを渡す！
                child: TripDetails(documentId: step.documentId),
              ),
            ),
          );
        },
      ),
    );
  }
}