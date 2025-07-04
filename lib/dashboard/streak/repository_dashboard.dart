import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/authentication/userdata.dart';
import 'package:fyp_proj/dashboard/quiz/quiz_model.dart';
import 'package:fyp_proj/dashboard/streak/streak_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // IMPORTANT: Replace with your actual user ID logic (e.g., from FirebaseAuth)
  static const String _streakBoxName = 'streakBox';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(StreakDataAdapter());
    await Hive.openBox<StreakData>(_streakBoxName);
  }

  Future<StreakData> getStreakData() async {
    final box = Hive.box<StreakData>(_streakBoxName);
    
    StreakData? localData = box.get(userData.userId);
    if (localData != null) {
      return localData;
    }

    try {
      final doc = await _firestore.collection('streak').doc(userData.userId).collection('progress').doc('streak').get();
      if (doc.exists) {
        final remoteData = StreakData.fromJson(doc.data()!);
        await box.put(userData.userId, remoteData);
        return remoteData;
      }
    } catch (e) {
      print("Error fetching from Firestore: $e");
    }
    return StreakData.initial();
  }

  Future<void> updateStreakData(StreakData data) async {
    final box = Hive.box<StreakData>(_streakBoxName);
    try {
      await _firestore.collection('streak').doc(userData.userId).collection('progress').doc('streak').set(data.toJson());
      await box.put(userData.userId, data);
    } catch (e) {
      print("Error updating streak data: $e");
      rethrow;
    }
  }

  Future<Quiz?> getDailyQuiz() async {
    try {
      // 1. 今日の日付を yyyy-MM-dd 形式で取得
      final String todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 2. quizzes コレクションから今日の日付のドキュメントを取得
      final quizDoc = await _firestore.collection('quizzes').doc(todayDateStr).get();

      if (!quizDoc.exists) {
        print("No quiz found for today ($todayDateStr)!");
        return null;
      }

      return Quiz.fromFirestore(quizDoc.data()!, quizDoc.id);

    } catch (e) {
      print("Error fetching today's quiz: $e");
      return null;
    }
  }
}