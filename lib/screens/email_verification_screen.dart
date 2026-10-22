import 'package:flutter/material.dart';

import 'privacy_consent_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color rose = Color(0xFFB04F6C);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color bodyText = Color(0xFF5E5652);
  static const Color borderColor = Color(0xFFEADFDB);

  // DEMO ONLY: This is not a real email verification code.
  static const String demoCode = '123456';

  final List<TextEditingController> codeControllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> codeFocusNodes = List.generate(6, (_) => FocusNode());

  bool isVerifying = false;

  @override
  void dispose() {
    for (final controller in codeControllers) {
      controller.dispose();
    }

    for (final node in codeFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Widget codeBox(int index) {
    return SizedBox(
      width: 42,
      height: 58,
      child: TextField(
        controller: codeControllers[index],
        focusNode: codeFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: forestGreen,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: rose,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            codeFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            codeFocusNodes[index - 1].requestFocus();
          }

          if (index == 5 && value.isNotEmpty) {
            codeFocusNodes[index].unfocus();
          }
        },
      ),
    );
  }

  void verifyEmail() {
    final String code =
        codeControllers.map((controller) => controller.text).join();

    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all six digits.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (code != demoCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Incorrect demo code. Please enter 123456.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isVerifying = true;
    });

    // DEMO ONLY: No email is sent and no real email ownership is checked.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyConsentScreen(),
      ),
    );
  }

  void resendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demo mode: no email is sent. Use code 123456 to continue.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
            color: Colors.white.withValues(alpha: 0.48),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo/logo.png',
                        height: 115,
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: rose.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(
                                color: blush,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mark_email_read_outlined,
                                color: rose,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Verify Your Email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color: forestGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'One small step to help keep your '
                              'Her Health account secure.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: bodyText,
                              ),
                            ),
                            const SizedBox(height: 25),
                            const Text(
                              'Email address for this demo',
                              style: TextStyle(
                                fontSize: 14,
                                color: bodyText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: rose,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Clear notice that this is demo verification.
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: blush.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.science_outlined,
                                    color: rose,
                                    size: 26,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'DEMO MODE — TESTING ONLY',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: forestGreen,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Enter this test code:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: bodyText,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '123456',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 5,
                                      color: rose,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'No email is sent. This does not '
                                    'confirm ownership of your email address.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: bodyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, codeBox),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isVerifying ? null : verifyEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: rose,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: isVerifying
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Verify Demo Code',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: resendCode,
                              style: TextButton.styleFrom(
                                foregroundColor: rose,
                              ),
                              child: const Text(
                                'Show Demo Code',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 17,
                                  color: Color(0xFF6E7B5F),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Demo verification is not real '
                                    'email security. Real verification '
                                    'must be connected before release.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: bodyText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Her Health · Your health, your journey.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: bodyText,
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
