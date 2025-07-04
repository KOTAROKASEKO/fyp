import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:fyp_proj/dashboard/streak/viewmodel_dashboard.dart'; // Adjust path
import 'package:fyp_proj/dashboard/streak/repository_dashboard.dart'; // Adjust path
import 'package:fyp_proj/dashboard/quiz/quiz_model.dart'; // Import the quiz model

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(repository: DashboardRepository()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  StreamSubscription? _animationSubscription;
  SMIInput<bool>? _isCorrectInput;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      _animationSubscription = viewModel.animationTrigger.listen((isCorrect) {
        _showStreakAnimationDialog(isCorrect);
      });
      // Initialize the ViewModel which loads the quiz
      viewModel.initializeDashboard();
    });
  }

  @override
  void dispose() {
    _animationSubscription?.cancel();
    super.dispose();
  }
  
  void _showStreakAnimationDialog(bool isCorrect) {
    _isCorrectInput?.value = isCorrect;

    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
             Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            height: 200,
            width: 200,
            child: RiveAnimation.asset(
              'assets/cat.riv',
              stateMachines: ['State Machine 1'],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("Daily Quiz")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, viewModel),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStreakHeader(viewModel),
        const SizedBox(height: 16),
        _buildStreakVisualizer(viewModel.weeklyStatus),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Expanded(
          child: _buildQuizArea(viewModel),
        ),
      ],
    );
  }
  
  Widget _buildQuizArea(DashboardViewModel viewModel) {
    if (viewModel.isAnswerSubmitted) {
      return const Center(
        child: Text(
          "Quiz completed for today! Come back tomorrow.",
          style: TextStyle(fontSize: 18, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    if (viewModel.currentQuiz == null) {
      return const Center(
        child: Text(
          "No quiz available right now. Please check back later.",
          style: TextStyle(fontSize: 18, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return _QuizCard(viewModel: viewModel);
  }

  Widget _buildStreakHeader(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quiz Streak!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Current Streak: ${viewModel.currentStreak} days",
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
        Text(
          "Total Points: ${viewModel.totalPoints}",
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStreakVisualizer(List<DayStreakStatus> weeklyStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final status = weeklyStatus[index];
        final String imagePath = status == DayStreakStatus.streaked
            ? 'assets/happy_cat.png'
            : 'assets/hungry_cat.png';

        return Column(
          children: [
            Image.asset(imagePath, width: 40, height: 40),
            const SizedBox(height: 4),
            Text("Day ${index + 1}", style: const TextStyle(color: Colors.white70)),
          ],
        );
      }),
    );
  }
}

// NEW WIDGET: To display and handle the quiz interaction
class _QuizCard extends StatelessWidget {
  final DashboardViewModel viewModel;
  const _QuizCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final quiz = viewModel.currentQuiz!;
    final bool isSubmitted = viewModel.isAnswerSubmitted;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            quiz.question,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...List.generate(quiz.options.length, (index) {
            return _buildOptionTile(context, index, quiz, viewModel);
          }),
          const SizedBox(height: 24),
          if (!isSubmitted)
            ElevatedButton(
              onPressed: viewModel.selectedAnswerIndex != null ? viewModel.submitAnswer : null,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Submit Answer", style: TextStyle(fontSize: 16)),
            ),
          if (isSubmitted)
            _buildExplanationCard(quiz),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, int index, Quiz quiz, DashboardViewModel viewModel) {
    final bool isSubmitted = viewModel.isAnswerSubmitted;
    final bool isSelected = viewModel.selectedAnswerIndex == index;
    final bool isCorrect = quiz.correctAnswerIndex == index;

    Color? tileColor;
    if (isSubmitted) {
      if (isCorrect) {
        tileColor = Colors.green.withOpacity(0.5);
      } else if (isSelected) {
        tileColor = Colors.red.withOpacity(0.5);
      }
    }

    return Card(
      color: tileColor,
      child: ListTile(
        leading: isSubmitted
            ? Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: Colors.white)
            : Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: Theme.of(context).primaryColor),
        title: Text(quiz.options[index]),
        onTap: isSubmitted ? null : () => viewModel.selectAnswer(index),
      ),
    );
  }
  
  Widget _buildExplanationCard(Quiz quiz) {
    return Card(
      color: Colors.blueGrey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Explanation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(quiz.explanation, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}