import 'package:flutter/material.dart';
import 'health_setup_screen.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool consentGiven = false;

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
            color: Colors.white.withValues(alpha: 0.25),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Logo
                  Image.asset(
                    'assets/images/logo/logo.png',
                    height: 110,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Your Privacy Matters 🔐",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Before you continue, please read how Her Health "
                    "will handle your personal and health information.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Privacy information card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.lock_outline,
                            size: 65,
                            color: Color(0xFFE89CB0),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "How we use your information",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF959B7D),
                          ),
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "Her Health may ask for personal and health "
                          "information so that we can provide a more "
                          "personalised healthcare experience.",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        privacyItem(
                          Icons.health_and_safety,
                          "Health information",
                          "Information about your health, symptoms, "
                              "healthcare journey and other information "
                              "you choose to provide.",
                        ),

                        privacyItem(
                          Icons.person_outline,
                          "Personal information",
                          "Information such as your name and other "
                              "details needed to provide the service.",
                        ),

                        privacyItem(
                          Icons.smart_toy_outlined,
                          "AI personalisation",
                          "Information you provide may be used to help "
                              "Her Health AI give responses that are more "
                              "relevant to your healthcare journey.",
                        ),

                        privacyItem(
                          Icons.security,
                          "Protecting your information",
                          "Your information should be protected using "
                              "appropriate security measures and access "
                              "controls.",
                        ),

                        const SizedBox(height: 10),

                        const Divider(),

                        const SizedBox(height: 10),

                        const Text(
                          "POPIA",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF959B7D),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "Her Health is designed with privacy and the "
                          "Protection of Personal Information Act (POPIA) "
                          "in mind. The final privacy notice, storage "
                          "location, retention period and other legal "
                          "requirements will be confirmed by the "
                          "organisation responsible for the application.",
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Consent checkbox
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F5F6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: CheckboxListTile(
                            value: consentGiven,
                            activeColor: const Color(0xFFE89CB0),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              "I have read and understand the privacy "
                              "information above.",
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                consentGiven = value ?? false;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: consentGiven
                                  ? const Color(0xFFE89CB0)
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: consentGiven
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HealthSetupScreen(),
                                      ),
                                    );
                                  }
                                : null,
                            child: const Text(
                              "Continue 🌸",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Your privacy is important to us. "
                    "Please only provide information you are comfortable sharing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget privacyItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFBECEF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE89CB0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
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
