import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'forgotpassword.dart';
import '../home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home':(context) => const HomeScreen(),
        '/forgot-password': (context) => ForgotPassword(),
      },
    );
  }
}