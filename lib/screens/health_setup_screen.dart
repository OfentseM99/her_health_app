import 'package:flutter/material.dart';
import 'package:her_health_app/screens/journey_questions_screen.dart';
import '../services/auth_service.dart';


class HealthSetupScreen extends StatefulWidget {
  const HealthSetupScreen({super.key});

  @override
  State<HealthSetupScreen> createState() => _HealthSetupScreenState();
}

class _HealthSetupScreenState extends State<HealthSetupScreen> {
  String? selectedJourney;

  final List<String> journeys = [
    "🤰 Pregnancy Care",
    "🌸 Menstrual Health",
    "👶 Postpartum Recovery",
    "💚 General Women's Health",
    "✨ Cosmetic Gynecology",
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
            color: Colors.white.withOpacity(0.25),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo/logo.png',
                    height: 110,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    (AuthService.firstName ?? '').isEmpty
                        ? "Welcome 🌸"
                        : "Welcome ${AuthService.firstName} 🌸",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Let's personalise your Her Health journey",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  const SizedBox(height: 35),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 15,
                          color: Colors.black12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 60,
                          color: Color(0xFFE89CB0),
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "Which best describes your current healthcare journey?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF959B7D),
                          ),
                        ),

                        const SizedBox(height: 25),

                        ...journeys.map(
                          (journey) => Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: RadioListTile<String>(
                              value: journey,
                              groupValue: selectedJourney,
                              activeColor: const Color(0xFFE89CB0),
                              title: Text(
                                journey,
                                style: const TextStyle(fontSize: 16),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  selectedJourney = value;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE89CB0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              if (selectedJourney == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please select your healthcare journey.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JourneyQuestionsScreen(
                                    journey: selectedJourney!,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Continue 🌸",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
