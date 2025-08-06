import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp_proj/features/1_authentication/userdata.dart';
import 'package:fyp_proj/features/2_daily_quiz/DATABASE/streak_data.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/generating_viewModel.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/plan_screen_viewmodel.dart';
import 'package:fyp_proj/features/4_plan/model/quiz_generation_model.dart';
import 'package:fyp_proj/features/3_discover/model/user_profile_model.dart';
import 'package:fyp_proj/features/app/app_main_screen.dart';
import 'package:fyp_proj/firebase_options.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RiveFile.initialize();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  await initHive();
  await _initFcm();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeneratingViewModel()),
        ChangeNotifierProvider(create: (_) => PlanScreenViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}


Future<void> _initFcm() async {
  final messaging = FirebaseMessaging.instance;

  // Request permission for iOS and Android 13+
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  // Get FCM token and store it in Hive box named 'profile'
  final fcmToken = await messaging.getToken();
  if (fcmToken != null) {
    print('FCM Token: $fcmToken');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm', fcmToken);
  }
}


Future<void> initHive() async {
  await Hive.initFlutter();
  // Register all adapters only if not registered yet
  if (!Hive.isAdapterRegistered(StreakDataAdapter().typeId)) {
    Hive.registerAdapter(StreakDataAdapter());
  }
  if (!Hive.isAdapterRegistered(UserProfileAdapter().typeId)) {
    Hive.registerAdapter(UserProfileAdapter());
  }
  if (!Hive.isAdapterRegistered(GeneratedQuizAdapter().typeId)) {
    Hive.registerAdapter(GeneratedQuizAdapter());
  }
  
  await Hive.openBox<GeneratedQuiz>('quizCache');
  await Hive.openBox<StreakData>('streakBox');
  await Hive.openBox<UserProfile>('userProfileBox');
  await Hive.openBox<GeneratedQuiz>('quizCache');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:MaterialApp(
        debugShowCheckedModeBanner: false,
      title: 'Voyage AI',
      theme: _buildTheme(context),
      home: StreamBuilder<User?>( 
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
            userData.initUserId();
            return const MainAppScreen();
          
        },
      ),
    ));
  }
}

ThemeData _buildTheme(BuildContext context) {
  const primaryColor = Color(0xFF0D47A1); // A deeper, more professional blue
  const secondaryColor = Color(0xFFFFC107); // A vibrant, complementary amber
  const backgroundColor = Color(0xFFFDFDFD); // A slightly off-white for a softer look
  const surfaceColor = Colors.white;
  final textTheme = Theme.of(context).textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // 1. Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: Colors.red.shade700,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),

    // 2. Typography
    textTheme: GoogleFonts.poppinsTextTheme(textTheme).copyWith(
      // You can further customize specific text styles here if needed
      displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w400),
      headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w400),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
    ),

    // 3. Component Themes
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: primaryColor,
      elevation: 0.5,
      iconTheme: IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}