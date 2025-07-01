import 'package:flutter/material.dart';
import 'package:fyp_proj/authentication/app.dart';
import 'package:firebase_core/firebase_core.dart';


void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialize Firebase here (e.g., await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);)
  // You will need to add firebase_core to your pubspec.yaml and generate DefaultFirebaseOptions.
  runApp(const MyApp());
}