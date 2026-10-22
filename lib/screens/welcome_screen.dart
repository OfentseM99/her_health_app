import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rose = Color(0xFFB04F6C);
    const forestGreen = Color(0xFF2F3A2A);
    const warmText = Color(0xFF5E5652);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Keep the existing background.
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Keep the existing soft overlay.
          Container(
            color: Colors.white.withValues(alpha: 0.20),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 550,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Keep the new logo.
                      Image.asset(
                        'assets/images/logo/logo.png',
                        height: 160,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Her Health',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: forestGreen,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Your wellness journey starts here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: warmText,
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rose,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
