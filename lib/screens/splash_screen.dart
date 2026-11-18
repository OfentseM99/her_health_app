import 'package:flutter/material.dart';
import '../theme/design_a.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import 'health_setup_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

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
      final biometricEnabled = await AuthService.isBiometricUnlockEnabled();

      if (biometricEnabled) {
        destination = const LoginScreen();
      } else {
        final loggedIn = await AuthService.restoreSession();

        if (loggedIn) {
          Map<String, dynamic>? journey;
          try {
            journey = await AuthService.getExistingHealthJourney();
          } catch (_) {
            journey = null;
          }

          destination = journey != null
              ? const DashboardScreen()
              : const HealthSetupScreen();
        }
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
      backgroundColor: DA.ground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo/logo.png', height: 140),
            const SizedBox(height: 20),
            Text('Her Health', style: DA.heading(36)),
            const SizedBox(height: 8),
            Text(
              'Your wellness journey starts here',
              style: DA.body(17, color: DA.muted),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: DA.rose),
            ),
          ],
        ),
      ),
    );
  }
}
