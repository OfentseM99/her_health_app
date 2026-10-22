import 'package:flutter/material.dart';
import 'health_setup_screen.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool consentGiven = false;

  static const Color rose = Color(0xFFB04F6C);
  static const Color lightRose = Color(0xFFD9879E);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color sage = Color(0xFF6E7B5F);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color bodyText = Color(0xFF5E5652);
  static const Color borderColor = Color(0xFFEADFDB);

  void continueToHealthSetup() {
    if (!consentGiven) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Existing background image.
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Soft overlay for readability.
          Container(
            color: Colors.white.withValues(alpha: 0.48),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 20,
              ),
              child: Column(
                children: [
                  // Existing Her Health logo.
                  Image.asset(
                    'assets/images/logo/logo.png',
                    height: 105,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Your Privacy Matters',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: forestGreen,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Before you continue, learn how Her Health '
                    'plans to handle your personal and health '
                    'information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: bodyText,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Main privacy card.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: borderColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: rose.withValues(alpha: 0.08),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: blush,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 36,
                              color: rose,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'How we use your information',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: forestGreen,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Her Health may ask for personal and '
                          'health information to support a more '
                          'personalised healthcare experience.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: bodyText,
                          ),
                        ),

                        const SizedBox(height: 25),

                        privacyItem(
                          Icons.health_and_safety_outlined,
                          'Health information',
                          'Details about your health, symptoms, '
                              'healthcare journey and other information '
                              'you choose to provide.',
                        ),

                        privacyItem(
                          Icons.person_outline,
                          'Personal information',
                          'Your name and other details needed to '
                              'provide the service.',
                        ),

                        privacyItem(
                          Icons.smart_toy_outlined,
                          'AI personalisation',
                          'Information you provide may help Her Health '
                              'AI tailor its responses to your '
                              'healthcare journey.',
                        ),

                        privacyItem(
                          Icons.security_outlined,
                          'Protecting your information',
                          'Appropriate security measures and access '
                              'controls should be used to help protect '
                              'your information.',
                        ),

                        const SizedBox(height: 5),

                        const Divider(
                          color: borderColor,
                          height: 30,
                        ),

                        const Row(
                          children: [
                            Icon(
                              Icons.gavel_outlined,
                              color: sage,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'POPIA',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: forestGreen,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'The Protection of Personal Information '
                          'Act (POPIA) governs how personal information '
                          'is processed in South Africa. Her Health '
                          'is being designed with privacy in mind. '
                          'The responsible organisation must confirm '
                          'the final privacy notice, storage practices, '
                          'retention periods and applicable legal '
                          'requirements.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: bodyText,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Consent checkbox.
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF6F3),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: borderColor,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: consentGiven,
                            activeColor: rose,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            title: const Text(
                              'I have read and understand the '
                              'privacy information above.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: forestGreen,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                consentGiven = value ?? false;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Continue button.
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                consentGiven ? continueToHealthSetup : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: rose,
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white70,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Icon(
                    Icons.favorite_border,
                    color: sage,
                    size: 20,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Your privacy matters. Only share information '
                    'you feel comfortable providing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: bodyText,
                    ),
                  ),

                  const SizedBox(height: 15),
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
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: blush,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: rose,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
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
                    fontSize: 14,
                    height: 1.5,
                    color: bodyText,
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
