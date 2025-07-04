import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp_proj/authentication/userdata.dart';
import 'package:fyp_proj/dashboard/quiz/quiz_model.dart';
import 'package:fyp_proj/dashboard/streak/repository_dashboard.dart';
import 'package:fyp_proj/dashboard/streak/streak_data.dart'; 

enum DayStreakStatus { streaked, notStreaked, future }

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository;

  // --- PROPERTIES ---

  // Loading State
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Streak & Points State
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _totalPoints = 0;
  int get totalPoints => _totalPoints;

  List<DayStreakStatus> _weeklyStatus = List.generate(7, (_) => DayStreakStatus.future);
  List<DayStreakStatus> get weeklyStatus => _weeklyStatus;
  
  // Quiz State
  Quiz? _currentQuiz;
  Quiz? get currentQuiz => _currentQuiz;

  int? _selectedAnswerIndex;
  int? get selectedAnswerIndex => _selectedAnswerIndex;

  bool _isAnswerSubmitted = false;
  bool get isAnswerSubmitted => _isAnswerSubmitted;

  // Animation Event Stream
  final StreamController<bool> _animationTriggerController = StreamController<bool>.broadcast();
  Stream<bool> get animationTrigger => _animationTriggerController.stream;

  // --- CONSTRUCTOR ---
  DashboardViewModel({required DashboardRepository repository}) : _repository = repository {
    initializeDashboard();
  }

  // --- INITIALIZATION ---
  Future<void> initializeDashboard() async {
    userData.initUserId();
    _isLoading = true;
    notifyListeners();

    final streakData = await _repository.getStreakData();
    // We check if the task for today is already done based on the loaded streak data.
    final today = _normalizeDate(DateTime.now());
    if (streakData.lastStreakDate != null && _normalizeDate(streakData.lastStreakDate!) == today) {
        _isAnswerSubmitted = true;
    }
    
    // Fetch streak data and quiz data concurrently for faster loading.
    await Future.wait([
      _loadStreakData(initialData: streakData), // Pass initial data to avoid a second read
      _loadQuiz(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadStreakData({StreakData? initialData}) async {
    final streakData = initialData ?? await _repository.getStreakData();
    
    _totalPoints = streakData.totalPoints;

    final today = _normalizeDate(DateTime.now());
    if (streakData.lastStreakDate == null) {
      _currentStreak = 0;
    } else {
      final lastDate = _normalizeDate(streakData.lastStreakDate!);
      if (today.difference(lastDate).inDays > 1) {
        _currentStreak = 0; // Streak is broken
      } else {
        _currentStreak = streakData.currentStreak;
      }
    }
    _updateWeeklyStatus();
  }

  Future<void> _loadQuiz() async {
    // Only load a new quiz if the task isn't already done for the day
    if (!_isAnswerSubmitted) {
      _currentQuiz = await _repository.getDailyQuiz();
    }
  }

  // --- QUIZ INTERACTION METHODS ---
  void selectAnswer(int index) {
    // Prevent changing answer after submission
    if (_isAnswerSubmitted) return;

    _selectedAnswerIndex = index;
    notifyListeners();
  }
  
  void submitAnswer() {
    if (_selectedAnswerIndex == null || _currentQuiz == null || _isAnswerSubmitted) return;

    final bool isCorrect = _selectedAnswerIndex == _currentQuiz!.correctAnswerIndex;
    _isAnswerSubmitted = true;
    
    // Call the master task completion method with the result
    completeTodayTask(isCorrect: isCorrect);
    
    // Notify UI to show correct/incorrect colors and lock the options
    notifyListeners();
  }
  
  // --- STREAK & POINTS UPDATE METHOD ---
  Future<void> completeTodayTask({required bool isCorrect}) async {
    // Trigger the Rive animation
    _animationTriggerController.add(isCorrect);
    
    // Since this method is only called on submission, we can be sure it's a new task.
    // (The `submitAnswer` method has guards to prevent re-submission).
    final currentData = await _repository.getStreakData();
    final today = _normalizeDate(DateTime.now());

    const int loginPoint = 1;
    const int correctBonus = 5;
    int pointsToAdd = loginPoint;
    if (isCorrect) {
      pointsToAdd += correctBonus;
    }
    final newTotalPoints = currentData.totalPoints + pointsToAdd;

    int newStreakCount;
    final lastDate = currentData.lastStreakDate != null ? _normalizeDate(currentData.lastStreakDate!) : null;
    if (lastDate != null && today.difference(lastDate).inDays == 1) {
      newStreakCount = currentData.currentStreak + 1;
    } else {
      newStreakCount = 1;
    }

    final newStreakData = StreakData(
      currentStreak: newStreakCount,
      lastStreakDate: today,
      totalPoints: newTotalPoints,
    );

    try {
      await _repository.updateStreakData(newStreakData);
      // Update local state to reflect the changes immediately
      _currentStreak = newStreakCount;
      _totalPoints = newTotalPoints;
      _updateWeeklyStatus();
      notifyListeners();
    } catch (e) {
      print("Failed to save streak: $e");
      // Optionally, revert the UI state or show an error
      _isAnswerSubmitted = false;
      notifyListeners();
    }
  }

  // --- HELPER METHODS & DISPOSE ---
  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _updateWeeklyStatus() {
    _weeklyStatus = List.generate(7, (index) {
      if (index < _currentStreak) {
        return DayStreakStatus.streaked;
      } else {
        return DayStreakStatus.notStreaked;
      }
    });
  }

  @override
  void dispose() {
    _animationTriggerController.close();
    super.dispose();
  }
}