// lib/screens/daily_quiz_screen.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_proj/features/1_authentication/auth_screen.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:fyp_proj/features/2_daily_quiz/viewmodel/viewmodel_dashboard.dart';
import 'package:fyp_proj/features/2_daily_quiz/DB_quiz.dart';
import 'package:fyp_proj/models/quiz_model.dart';

// The new screen that will be a tab in the main navigation
class DailyQuizScreen extends StatefulWidget {
  // This screen will be used as a tab in the main navigation
  // It will keep its state when switching tabs
  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen>with AutomaticKeepAliveClientMixin {
  

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(repository: DashboardRepository()),
      child: const _DashboardView(), // This remains the same as your implementation
    );
  }
}

// The rest of the code is identical to your provided 'view_dashboard.dart'
// I've renamed the class for clarity
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
      // Initialize the ViewModel which loads the quiz and ranking
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
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text(
                    'Dashboard Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                ListTile(
                  title: const Text('Settings'),
                  onTap: () {
                    // Handle settings tap
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Logout'),
                  onTap: () async {
                    // Handle logout tap
                    Navigator.pop(context);
                    // Firebase logout logic
                    try {
                      await Future.delayed(const Duration(
                          milliseconds:
                              100)); // Optional: allow drawer to close
                      await FirebaseAuth.instance.signOut();
                      // Navigate to login screen or root
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AuthScreen(), // Ensure you have this screen implemented
                          ));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(centerTitle: true, title: const Text("Daily Quiz")),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DashboardViewModel viewModel) {
    // A modern, scrollable layout for the dashboard with a new structure.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SizedBox(
          height: 150,
          child: RiveAnimation.asset('assets/cat_relax.riv',
              fit: BoxFit.contain),
        ),
        const SizedBox(height: 24),
        // --- 1. QUIZ SECTION ---
        if (viewModel.currentQuiz != null)
          _QuizCard(viewModel: viewModel)
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: Text(
                "No quiz available for today. Please check back later.",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 24),

        // --- 2. STREAK CARD ---
        _buildStreakCard(context, viewModel),
        const SizedBox(height: 24),

        // --- 3. RANKING CARD ---
        _buildRankingCard(context, viewModel),
        const SizedBox(height: 16),
      ],
    );
  }

  /// NEW WIDGET: A dedicated card for streak information.
  Widget _buildStreakCard(
      BuildContext context, DashboardViewModel viewModel) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quiz Streak",
              style:
                  textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Points: ${viewModel.totalPoints} pt",
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStreakVisualizer(viewModel.weeklyStatus),
          ],
        ),
      ),
    );
  }

  /// NEW WIDGET: A dedicated card for ranking and leaderboard.
  Widget _buildRankingCard(
      BuildContext context, DashboardViewModel viewModel) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Leaderboard",
              style:
                  textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your Rank
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Rank",
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${viewModel.myRank > 0 ? viewModel.myRank : 'N/A'}",
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Top Rankers List
                Expanded(
                  flex: 2, // Give more space to the list
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Top Rankers",
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (viewModel.ranking.isEmpty)
                        const Text("No ranking data yet.")
                      else
                        ...viewModel.ranking.map((user) {
                          final index = viewModel.ranking.indexOf(user);
                          final isCurrentUser = user['userId'] == userData.userId;
                          final displayId = user['userId'].length > 6
                              ? '${user['userId'].substring(0, 6)}...'
                              : user['userId'];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Text(
                                  "${index + 1}. ",
                                  style: TextStyle(
                                    fontWeight: isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    displayId,
                                    style: TextStyle(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${user['totalPoints']} pt",
                                  style: TextStyle(
                                    fontWeight: isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrentUser
                                        ? colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // UPDATED WIDGET: Displays dynamic points and has a cleaner design.
  Widget _buildStreakVisualizer(List<DayStreakStatus> weeklyStatus) {
    final pointsPerDay = [1, 1, 5, 1, 1, 1, 100];
    final days = ["D1", "D2", "D3", "D4", "D5", "D6", "D7"];
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final status = weeklyStatus[index];
        final isStreaked = status == DayStreakStatus.streaked;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStreaked
                    ? colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
              child: Image.asset(
                isStreaked ? 'assets/happy_cat.png' : 'assets/hungry_cat.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(height: 4),
            Text(days[index], style: Theme.of(context).textTheme.bodySmall),
            // IMPORTANT: Displays points for each day.
            Text(
              "+${pointsPerDay[index]} pt",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isStreaked ? colorScheme.primary : Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final DashboardViewModel viewModel;
  const _QuizCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final quiz = viewModel.currentQuiz!;
    final bool isSubmitted = viewModel.isAnswerSubmitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Q. ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(
                text: quiz.question,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 20),
        ...List.generate(quiz.options.length, (index) {
          return _buildOptionTile(context, index, quiz, viewModel);
        }),
        const SizedBox(height: 20),
        if (!isSubmitted)
          ElevatedButton(
            onPressed: viewModel.selectedAnswerIndex != null
                ? () => viewModel.submitAnswer()
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Submit Answer"),
          ),
        if (isSubmitted)
          Center(
            child: Text(
              "You have completed today's quiz!",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  // UPDATED WIDGET: Uses Card and InkWell for a more modern feel.
  Widget _buildOptionTile(
      BuildContext context, int index, Quiz quiz, DashboardViewModel viewModel) {
    final bool isSubmitted = viewModel.isAnswerSubmitted;
    final bool isSelected = viewModel.selectedAnswerIndex == index;
    final bool isCorrect = quiz.correctAnswerIndex == index;

    final int totalVotes = quiz.totalVotes;
    final double percentage = (totalVotes > 0 &&
            index < quiz.answerDistribution.length)
        ? (quiz.answerDistribution[index] / totalVotes) * 100
        : 0;

    Color? tileColor;
    Color? borderColor;

    if (isSubmitted) {
      if (isCorrect) {
        tileColor = Colors.green.withOpacity(0.15);
      }
      if (isSelected) {
        borderColor = isCorrect ? Colors.green.shade700 : Colors.red.shade700;
        tileColor = isCorrect
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3);
      }
    } else if (isSelected) {
      borderColor = Theme.of(context).primaryColor;
    }

    return Card(
      elevation: 0,
      color: tileColor ?? Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: 2,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: isSubmitted ? null : () => viewModel.selectAnswer(index),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (isSubmitted)
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.options[index],
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (isSubmitted)
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}