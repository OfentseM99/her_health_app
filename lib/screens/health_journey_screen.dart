import 'package:flutter/material.dart';
import 'journey_questions_screen.dart';

class HealthJourneyScreen extends StatelessWidget {
  const HealthJourneyScreen({super.key});

  static const Color rose = Color(0xFFB04F6C);
  static const Color lightRose = Color(0xFFD9879E);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);

  final List<Map<String, dynamic>> journeys = const [
    {
      'title': 'Pregnancy Care',
      'description': 'Support and guidance throughout your pregnancy.',
      'icon': Icons.pregnant_woman_outlined,
      'emoji': '',
    },
    {
      'title': 'Menstrual Health',
      'description': 'Understand your cycle and track your menstrual health.',
      'icon': Icons.calendar_month_outlined,
      'emoji': '🌸',
    },
    {
      'title': 'Postpartum Recovery',
      'description':
          'Support for your recovery and wellbeing after childbirth.',
      'icon': Icons.child_care_outlined,
      'emoji': '👶',
    },
    {
      'title': "General Women's Health",
      'description':
          'Build healthy habits and learn more about your wellbeing.',
      'icon': Icons.health_and_safety_outlined,
      'emoji': '💚',
    },
    {
      'title': 'Cosmetic Gynecology',
      'description':
          'Explore questions about intimate wellness and procedures.',
      'icon': Icons.spa_outlined,
      'emoji': '✨',
    },
  ];

  void selectJourney(BuildContext context, String journey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JourneyQuestionsScreen(journey: journey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Keep the existing background image.
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          Container(
            color: Colors.white.withValues(alpha: 0.28),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Go back',
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: rose,
                            size: 27,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Image.asset(
                          'assets/images/logo/logo.png',
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Choose Your Health Journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Every woman’s journey is different. '
                        'Choose the area you would like support with '
                        'and let’s take the next step together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: warmText,
                        ),
                      ),
                      const SizedBox(height: 26),
                      for (final journey in journeys) ...[
                        _JourneyCard(
                          title: journey['title'] as String,
                          description: journey['description'] as String,
                          icon: journey['icon'] as IconData,
                          onTap: () => selectJourney(
                            context,
                            journey['title'] as String,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Your health journey, supported with care.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: warmText,
                        ),
                      ),
                      const SizedBox(height: 12),
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

class _JourneyCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _JourneyCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  static const Color rose = Color(0xFFB04F6C);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: blush,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: rose,
                  size: 29,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: forestGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: warmText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: rose,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
