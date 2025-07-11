// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp_proj/features/1_authentication/auth_screen.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/2_daily_quiz/DATABASE/DB_quiz.dart';
import 'package:fyp_proj/features/2_daily_quiz/DATABASE/streak_data.dart';
import 'package:fyp_proj/features/5_profile/model/user_profile_model.dart';
import 'package:fyp_proj/features/app/app_main_screen.dart';
import 'package:fyp_proj/firebase_options.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  await  initHive();
  runApp(const MyApp());
}

Future<void> initHive() async {
  await Hive.initFlutter();
  // Register all adapters
  Hive.registerAdapter(StreakDataAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  // Open all boxes
  await Hive.openBox<StreakData>('streakBox');
  await Hive.openBox<UserProfile>('userProfileBox');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voyage AI', // Changed app title for inspiration
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          primary: Colors.blueAccent,
          secondary: Colors.amber,
          surface: Colors.white,
          background: const Color(0xFFF8F9FA), // A lighter, cleaner background
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: const Color.fromARGB(221, 88, 88, 88),
          onSurface: const Color.fromARGB(221, 50, 50, 50),
          onBackground: const Color.fromARGB(221, 78, 78, 78),
          onError: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>( // Explicitly type the stream
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            userData.initUserId();
            return const MainAppScreen();
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}