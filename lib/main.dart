import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/period_tracker_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/user_qr_screen.dart';

void main() {
  runApp(const HerHealthApp());
}

class HerHealthApp extends StatelessWidget {
  const HerHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Her Health',

      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFB04F6C),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB04F6C),
          primary: const Color(0xFFB04F6C),
          secondary: const Color(0xFF6E7B5F),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2F3A2A),
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF2F3A2A),
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF2F3A2A),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF2F3A2A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF2F3A2A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF5E5652),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF5E5652),
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB04F6C),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB04F6C),
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(
              color: Color(0xFFB04F6C),
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Color(0xFF5E5652),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFEADFDB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFEADFDB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFB04F6C),
              width: 2,
            ),
          ),
        ),
      ),

      // Temporary startup screen for testing.
      home: const AppStartScreen(),

      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/period-tracker': (context) => const PeriodTrackerScreen(),
        '/dashboard': (context) => const PatientDashboardScreen(),
        '/user-qr': (context) => const UserQrScreen(),
      },
    );
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFB04F6C),
        ),
      ),
    );
  }
}
