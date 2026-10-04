import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import 'health_setup_screen.dart';
import 'chatbot_screen.dart';

/// First screen the app shows. While the logo is on screen it checks for a
/// saved login, then sends the patient to the right place:
///   - saved login + existing health journey -> chatbot
///   - saved login, no journey yet           -> health setup
///   - no saved login / expired              -> welcome screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideWhereToGo();
  }

  Future<void> _decideWhereToGo() async {
    // Keep the splash up briefly so it doesn't just flash past.
    final minimumDisplay = Future.delayed(const Duration(milliseconds: 1200));

    Widget destination = const WelcomeScreen();

    try {
      final loggedIn = await AuthService.restoreSession();

      if (loggedIn) {
        Map<String, dynamic>? journey;
        try {
          journey = await AuthService.getExistingHealthJourney();
        } catch (_) {
          journey = null;
        }

        destination = journey != null
            ? const ChatbotScreen()
            : const HealthSetupScreen();
      }
    } catch (_) {
      // Anything unexpected: fall back to the normal welcome flow.
      destination = const WelcomeScreen();
    }

    await minimumDisplay;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (NOT BLURRED)
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Slight transparent overlay for readability
          Container(
            color: Colors.white.withOpacity(0.25),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo/logo.png',
                  height: 160,
                ),

                const SizedBox(height: 25),

                Text(
                  "Her Health",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sageGreen,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Your wellness journey starts here",
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 30),

                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
