import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/model/quiz_generation_model.dart';
import 'package:fyp_proj/features/4_plan/repository/quiz_generation_repository.dart';

class QuizGenerationViewModel extends ChangeNotifier {
  final QuizGenerationRepository _repository = QuizGenerationRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<GeneratedQuiz> _quiz = [];
  List<GeneratedQuiz> get quiz => _quiz;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  int? _selectedOptionIndex;
  int? get selectedOptionIndex => _selectedOptionIndex;

  bool _isAnswered = false;
  bool get isAnswered => _isAnswered;

  int _score = 0;
  int get score => _score;

  QuizGenerationViewModel(String destination) {
    generateQuiz(destination);
  }

  Future<void> generateQuiz(String destination) async {
    try {
      _isLoading = true;
      notifyListeners();

      _quiz = await _repository.getQuiz(destination);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to generate quiz: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadQuiz(String destination) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Call the new repository method that includes caching logic
      _quiz = await _repository.getQuiz(destination);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load quiz: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectOption(int index) {
    if (!_isAnswered) {
      _selectedOptionIndex = index;
      notifyListeners();
    }
  }

  void submitAnswer() {
    if (_selectedOptionIndex != null && !_isAnswered) {
      _isAnswered = true;
      if (_selectedOptionIndex == _quiz[_currentQuestionIndex].correctOptionIndex) {
        _score++;
      }
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _quiz.length - 1) {
      _currentQuestionIndex++;
      _selectedOptionIndex = null;
      _isAnswered = false;
      notifyListeners();
    } else {
      // End of quiz
    }
  }

  void resetQuiz(String destination) {
    _isLoading = true;
    _quiz = [];
    _errorMessage = null;
    _currentQuestionIndex = 0;
    _selectedOptionIndex = null;
    _isAnswered = false;
    _score = 0;
    generateQuiz(destination);
  }
}