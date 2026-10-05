import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/period_tracker_screen.dart';
import 'screens/patient_dashboard_screen.dart';

void main() {
  runApp(const HerHealthApp());
}

class HerHealthApp extends StatelessWidget {
  const HerHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Her Health",

      theme: ThemeData(
        primaryColor: const Color(0xFFE89CB0),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE89CB0),
          primary: const Color(0xFFE89CB0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE89CB0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),

      // ==================================================
      // STARTING SCREEN
      // ==================================================
      //
      // AppStartScreen checks whether the patient has
      // already logged in before deciding where to go.
      //
      home: const AppStartScreen(),

      // ==================================================
      // ROUTES
      // ==================================================

      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/period-tracker': (context) => const PeriodTrackerScreen(),
        '/dashboard': (context) => const PatientDashboardScreen(),
      },
    );
  }
}

// ======================================================
// APP START SCREEN
// ======================================================
//
// This screen decides what the user sees when opening
// Her Health.
//
// New user:
// Welcome screen
//
// Returning user:
// Login screen
//
// Once the backend is connected, this can also be used
// for automatic secure authentication.
// ======================================================

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  @override
  void initState() {
    super.initState();

    checkLoginStatus();
  }

  // ==================================================
  // CHECK LOGIN STATUS
  // ==================================================

  Future<void> checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    // ==================================================
    // RETURNING USER
    // ==================================================

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );

      return;
    }

    // ==================================================
    // NEW USER
    // ==================================================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
    );
  }

  // ==================================================
  // LOADING SCREEN
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE89CB0),
        ),
      ),
    );
  }
}
