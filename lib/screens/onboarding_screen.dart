import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'information_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const Color rose = Color(0xFFB04F6C);
  static const Color blushPink = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);
  static const Color sageGreen = Color(0xFF6E7B5F);

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white.withValues(alpha: 0.30),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo/logo.png',
                        height: 140,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Her Health',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: forestGreen,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Your personal health companion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: warmText,
                        ),
                      ),

                      const SizedBox(height: 28),

                      buildInfoCard(
                        icon: Icons.auto_awesome_outlined,
                        title: 'AI Health Companion',
                        description:
                            'Get trusted health information, receive personalised guidance, and ask questions anytime.',
                      ),

                      buildInfoCard(
                        icon: Icons.favorite_border,
                        title: 'Track Your Health',
                        description:
                            'Monitor your menstrual cycle, pregnancy, symptoms, and appointments in one place.',
                      ),

                      buildInfoCard(
                        icon: Icons.medical_services_outlined,
                        title: 'Stay Connected',
                        description:
                            'Request appointments, receive reminders, and keep your health journey organised.',
                      ),

                      const SizedBox(height: 20),

                      // Create account button.
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
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Outlined login button.
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: rose,
                            side: const BorderSide(
                              color: rose,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InformationScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.menu_book_outlined,
                          color: sageGreen,
                        ),
                        label: const Text(
                          'Learn More About Her Health',
                          style: TextStyle(
                            color: sageGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: blushPink,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: rose,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: warmText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
