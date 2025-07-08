import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/models/quiz_model.dart';
import 'package:fyp_proj/features/2_daily_quiz/streak_data.dart';
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
    final userStreakProgressRef = _firestore.collection('streak').doc(userData.userId).collection('progress').doc('streak');
    final userStreakDocRef = _firestore.collection('streak').doc(userData.userId); // 親ドキュメント

    try {
      // トランザクションを使用して、両方のドキュメントをアトミックに更新
      await _firestore.runTransaction((transaction) async {
        transaction.set(userStreakProgressRef, data.toJson());
        // 親ドキュメントにtotalPointsを保存してランキングクエリを可能にする
        transaction.set(userStreakDocRef, {'totalPoints': data.totalPoints}, SetOptions(merge: true));
      });

      await box.put(userData.userId, data);
    } catch (e) {
      print("Error updating streak data: $e");
      rethrow;
    }
  }

  Future<Quiz?> getDailyQuiz() async {
    try {
      // 1. 今日の日付をyyyy-MM-dd 形式で取得
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

  // NEW: Method to update the vote count for a quiz option
  Future<void> updateUserVote(String quizId, int optionIndex) async {
    final quizRef = _firestore.collection('quizzes').doc(quizId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(quizRef);
        if (!snapshot.exists) {
          throw Exception("Quiz does not exist!");
        }

        // Get current distribution, or initialize it if it's not there
        final data = snapshot.data()!;
        final distribution = List<int>.from(data['answerDistribution'] ?? List.generate(data['options']?.length ?? 0, (_) => 0));

        // Ensure the distribution list is long enough
        while (distribution.length <= optionIndex) {
          distribution.add(0);
        }

        // Increment the vote for the selected option
        distribution[optionIndex]++;

        // Update the document in the transaction
        transaction.update(quizRef, {'answerDistribution': distribution});
      });
      print("Vote updated successfully for quiz $quizId");
    } catch (e) {
      print("Error updating vote: $e");
      // Decide if you want to rethrow or handle the error gracefully
    }
  }

  // NEW: ランキング上位を取得するメソッド
  Future<List<Map<String, dynamic>>> getTopUsers(int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('streak')
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      final ranking = querySnapshot.docs.map((doc) {
        return {
          'userId': doc.id,
          'totalPoints': doc.data()['totalPoints'] ?? 0,
        };
      }).toList();
      return ranking;
    } catch (e) {
      print("Error getting top users: $e. Firestore index might be required.");
      return [];
    }
  }

  // NEW: 自分の順位を取得するメソッド
  Future<int> getMyRank(int myTotalPoints) async {
    try {
      final aggregateQuery = _firestore
          .collection('streak')
          .where('totalPoints', isGreaterThan: myTotalPoints)
          .count();
      final aggregateQuerySnapshot = await aggregateQuery.get();

      return (aggregateQuerySnapshot.count ?? 0) + 1;
    } catch (e) {
      print("Error getting my rank: $e");
      return -1; // エラー時は -1 を返す
    }
  }
}