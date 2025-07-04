import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Assuming you have a Firebase config
import 'package:fyp_proj/authentication/auth_screen.dart';
import 'package:fyp_proj/dashboard/streak/repository_dashboard.dart'; 
import 'package:fyp_proj/dashboard/view_dashboard.dart'; // Adjust path

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize external services like Firebase and your database
  await Firebase.initializeApp(); // Replace with your Firebase init if needed
  await initDatabase();

  // 3. Run the app only after all initializations are complete
  runApp(const MyApp());
}

// This function now properly awaits the Hive initialization
Future<void> initDatabase() async {
  await DashboardRepository.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streak App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const DashboardScreen();
          } else {
            return const AuthScreen(); // Make sure you have this screen implemented
          }
        },
      ),
    );
  }
}