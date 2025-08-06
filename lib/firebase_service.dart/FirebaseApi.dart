import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // 1. 通知の許可をリクエスト
    await _firebaseMessaging.requestPermission();

    // 2. FCMトークンを取得
    final String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print("FCM Token: $fcmToken");
      await saveTokenToDatabase(fcmToken);
    }

    // 3. トークンが更新されたらDBも更新
    _firebaseMessaging.onTokenRefresh.listen(saveTokenToDatabase);
  }

  Future<void> saveTokenToDatabase(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set(
        {'fcmToken': token},
        SetOptions(merge: true), // 既存のフィールドを上書きしない
      );
      print("FCM token saved to Firestore.");
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }
}