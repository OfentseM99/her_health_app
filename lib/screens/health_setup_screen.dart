import 'package:flutter/material.dart';
import 'package:her_health_app/screens/journey_questions_screen.dart';

class HealthSetupScreen extends StatefulWidget {
  const HealthSetupScreen({super.key});

  @override
  State<HealthSetupScreen> createState() => _HealthSetupScreenState();
}

class _HealthSetupScreenState extends State<HealthSetupScreen> {
  static const Color rose = Color(0xFFB04F6C);
  static const Color blushPink = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);

  String? selectedJourney;

  final List<Map<String, dynamic>> journeys = [
    {
      'title': 'Pregnancy Care',
      'description': 'Support throughout your pregnancy journey.',
      'icon': Icons.pregnant_woman_outlined,
    },
    {
      'title': 'Menstrual Health',
      'description': 'Understand and track your menstrual cycle.',
      'icon': Icons.calendar_month_outlined,
    },
    {
      'title': 'Postpartum Recovery',
      'description': 'Care and support after giving birth.',
      'icon': Icons.child_care_outlined,
    },
    {
      'title': "General Women's Health",
      'description': 'Everyday wellness and preventive care.',
      'icon': Icons.health_and_safety_outlined,
    },
    {
      'title': 'Cosmetic Gynecology',
      'description': 'Explore intimate health and wellness information.',
      'icon': Icons.spa_outlined,
    },
  ];

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
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo/logo.png',
                        height: 105,
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Welcome to Her Health',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Let's personalise your health journey.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: warmText,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: cardBorder),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 18,
                              color: Colors.black12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: blushPink,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.favorite_border,
                                size: 34,
                                color: rose,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Which best describes your current healthcare journey?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                                color: forestGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choose the option that best fits your needs.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: warmText,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ...journeys.map((journey) {
                              final title = journey['title'] as String;
                              final isSelected = selectedJourney == title;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? blushPink.withValues(alpha: 0.65)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected ? rose : cardBorder,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: RadioListTile<String>(
                                  value: title,
                                  groupValue: selectedJourney,
                                  activeColor: rose,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                  secondary: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: blushPink,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      journey['icon'] as IconData,
                                      color: rose,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: forestGreen,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      journey['description'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: warmText,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedJourney = value;
                                    });
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
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
                                  if (selectedJourney == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select your healthcare journey.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          JourneyQuestionsScreen(
                                        journey: selectedJourney!,
                                      ),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
