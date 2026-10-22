import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  static const rose = Color(0xFFB04F6C);
  static const blushPink = Color(0xFFF6DCE2);
  static const forestGreen = Color(0xFF2F3A2A);
  static const warmText = Color(0xFF5E5652);
  static const cardBorder = Color(0xFFEADFDB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.white.withValues(alpha: 0.25),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo/logo.png',
                        height: 115,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'About Her Health',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your personal health companion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: warmText,
                        ),
                      ),
                      const SizedBox(height: 28),
                      infoCard(
                        icon: Icons.auto_awesome_outlined,
                        title: 'AI Health Companion',
                        description: 'Get trusted health information, receive '
                            'personalised guidance, and ask questions anytime.',
                      ),
                      infoCard(
                        icon: Icons.favorite_border,
                        title: 'Track Your Health',
                        description:
                            'Monitor your menstrual cycle, pregnancy journey, '
                            'symptoms and appointments in one place.',
                      ),
                      infoCard(
                        icon: Icons.medical_services_outlined,
                        title: 'Stay Connected',
                        description:
                            'Request appointments, receive reminders, and '
                            'keep your health journey organised.',
                      ),
                      infoCard(
                        icon: Icons.health_and_safety_outlined,
                        title: 'Your Health Matters',
                        description:
                            'Her Health is designed to support women with '
                            'accessible healthcare information and guidance.',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rose,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  Widget infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: blushPink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: rose,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
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
