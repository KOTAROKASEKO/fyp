import 'package:firebase_auth/firebase_auth.dart';

class userData{
  static String _userId = "";
  static String get userId => _userId;

  // Initialize the user ID, typically called when the user logs in
  static void initUserId() {
    _userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  }
}