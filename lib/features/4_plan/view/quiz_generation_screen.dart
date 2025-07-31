import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp_proj/features/4_plan/viewmodel/quiz_generation_viewmodel.dart';

class QuizGenerationScreen extends StatelessWidget {
  final String destination;

  const QuizGenerationScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizGenerationViewModel(destination),
      child: Consumer<QuizGenerationViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Quiz for $destination'),
              actions: [
                if (!viewModel.isLoading && viewModel.errorMessage == null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => viewModel.resetQuiz(destination),
                  )
              ],
            ),
            body: _buildBody(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizGenerationViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            viewModel.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (viewModel.quiz.isEmpty) {
      return const Center(child: Text('No quiz generated.'));
    }

    if (viewModel.currentQuestionIndex >= viewModel.quiz.length) {
      return _buildQuizResult(context, viewModel);
    }

    final currentQuiz = viewModel.quiz[viewModel.currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${viewModel.currentQuestionIndex + 1}/${viewModel.quiz.length}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            currentQuiz.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ...List.generate(currentQuiz.options.length, (index) {
            return _buildOption(context, viewModel, index);
          }),
          const Spacer(),
          if (viewModel.isAnswered)
            Card(
              color: Colors.lightBlue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explanation',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(currentQuiz.explanation),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: viewModel.selectedOptionIndex != null
                ? () {
                    if (viewModel.isAnswered) {
                      viewModel.nextQuestion();
                    } else {
                      viewModel.submitAnswer();
                    }
                  }
                : null,
            child: Text(viewModel.isAnswered ? 'Next Question' : 'Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, QuizGenerationViewModel viewModel, int index) {
    final currentQuiz = viewModel.quiz[viewModel.currentQuestionIndex];
    final isSelected = viewModel.selectedOptionIndex == index;
    final isCorrect = index == currentQuiz.correctOptionIndex;

    Color? tileColor;
    if (viewModel.isAnswered) {
      if (isCorrect) {
        tileColor = Colors.green.withOpacity(0.3);
      } else if (isSelected) {
        tileColor = Colors.red.withOpacity(0.3);
      }
    }

    return Card(
      color: tileColor,
      child: ListTile(
        onTap: () => viewModel.selectOption(index),
        title: Text(currentQuiz.options[index]),
        leading: Radio<int>(
          value: index,
          groupValue: viewModel.selectedOptionIndex,
          onChanged: (_) => viewModel.selectOption(index),
        ),
      ),
    );
  }

  Widget _buildQuizResult(BuildContext context, QuizGenerationViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Score: ${viewModel.score}/${viewModel.quiz.length}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => viewModel.resetQuiz(destination),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

}