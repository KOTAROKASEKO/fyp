// <file:dashboard/streak/viewmodel_dashboard.dart>
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/models/quiz_model.dart';
import 'package:fyp_proj/features/2_daily_quiz/DB_quiz.dart';
import 'package:fyp_proj/features/2_daily_quiz/streak_data.dart';

enum DayStreakStatus { streaked, notStreaked, future }

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository;


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

  // NEW: Ranking State
  List<Map<String, dynamic>> _ranking = [];
  List<Map<String, dynamic>> get ranking => _ranking;

  int _myRank = 0;
  int get myRank => _myRank;

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

    // Fetch streak, quiz, and ranking data concurrently for faster loading.
    await Future.wait([
      _loadStreakData(initialData: streakData), // Pass initial data to avoid a second read
      _loadQuiz(),
      _loadRankingData(streakData.totalPoints), // Load ranking data
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
    // MODIFIED: Fetch the quiz regardless of submission status.
    // This ensures that the user can see the quiz results even after completing it.
    _currentQuiz = await _repository.getDailyQuiz();
  }

  // NEW: Method to load ranking data
  Future<void> _loadRankingData(int myPoints) async {
    // Fetch top users and my rank concurrently
    final results = await Future.wait([
      _repository.getTopUsers(5), // Fetch top 5 users
      _repository.getMyRank(myPoints),
    ]);
    _ranking = results[0] as List<Map<String, dynamic>>;
    _myRank = results[1] as int;
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

    // --- NEW: Update the vote count in Firestore ---
    // We do this without waiting for it to complete to keep the UI responsive
    _repository.updateUserVote(_currentQuiz!.id, _selectedAnswerIndex!);

    // Call the master task completion method with the result
    completeTodayTask(isCorrect: isCorrect);

    // Notify UI to show correct/incorrect colors and lock the options
    // This is now handled within completeTodayTask after data is saved
  }

  // --- STREAK & POINTS UPDATE METHOD ---
  Future<void> completeTodayTask({required bool isCorrect}) async {
    // Trigger the Rive animation
    _animationTriggerController.add(isCorrect);

    final currentData = await _repository.getStreakData();
    final today = _normalizeDate(DateTime.now());

    const int correctBonus = 5;
    int basePointsForDay = 1;

    int newStreakCount;
    final lastDate = currentData.lastStreakDate != null ? _normalizeDate(currentData.lastStreakDate!) : null;
    if (lastDate != null && today.difference(lastDate).inDays == 1) {
      newStreakCount = currentData.currentStreak + 1;
    } else if (lastDate == today) {
      newStreakCount = currentData.currentStreak;
    }
    else {
      newStreakCount = 1;
    }

    // Apply tiered points based on newStreakCount
    if (newStreakCount == 3) {
      basePointsForDay = 5;
    } else if (newStreakCount == 7) {
      basePointsForDay = 100;
    }

    int pointsToAdd = basePointsForDay;
    if (isCorrect) {
      pointsToAdd += correctBonus;
    }

    final newTotalPoints = currentData.totalPoints + pointsToAdd;


    final newStreakData = StreakData(
      currentStreak: newStreakCount,
      lastStreakDate: today,
      totalPoints: newTotalPoints,
    );

    try {
      await _repository.updateStreakData(newStreakData);
      // Update local state to reflect the changes immediately
      _currentStreak = newStreakData.currentStreak;
      _totalPoints = newStreakData.totalPoints;
      _isAnswerSubmitted = true; // Mark as submitted
      _updateWeeklyStatus();

      // NEW: Reload ranking data after points update
      await _loadRankingData(newTotalPoints);

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