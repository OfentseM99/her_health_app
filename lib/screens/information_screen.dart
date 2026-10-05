import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Soft overlay
          Container(
            color: Colors.white.withValues(alpha: 0.30),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo/logo.png',
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "About Her Health 🌸",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF959B7D),
                      ),
                    ),
                    const SizedBox(height: 30),
                    infoCard(
                      "🤖 AI Health Companion",
                      "Get trusted health information, receive personalised "
                          "guidance, and ask questions anytime.",
                    ),
                    infoCard(
                      "❤️ Track Your Health",
                      "Monitor your menstrual cycle, pregnancy journey, "
                          "symptoms and appointments in one place.",
                    ),
                    infoCard(
                      "👩‍⚕️ Stay Connected",
                      "Request appointments, receive reminders, and keep "
                          "your health journey organised.",
                    ),
                    infoCard(
                      "🔒 Your Health Matters",
                      "Her Health is designed to support women with "
                          "accessible healthcare information and guidance.",
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE89CB0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Back",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget infoCard(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          )
        ],
      ),
    );
  }
}
