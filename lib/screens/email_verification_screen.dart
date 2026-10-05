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
  final List<TextEditingController> codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final controller in codeControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget codeBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: codeControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFE89CB0),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  void verifyEmail() {
    // Backend email verification will be connected later.
    // For now, continue to the Privacy & POPIA screen.

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyConsentScreen(),
      ),
    );
  }

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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo/logo.png',
                      height: 130,
                    ),

                    const SizedBox(height: 25),

                    // Title
                    const Text(
                      "Verify Your Email 💌",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF959B7D),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "We've sent a verification code to:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Email
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE89CB0),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Verification code boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        codeBox(0),
                        codeBox(1),
                        codeBox(2),
                        codeBox(3),
                        codeBox(4),
                        codeBox(5),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Verify button
                    SizedBox(
                      width: 280,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE89CB0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: verifyEmail,
                        child: const Text(
                          "Verify Email",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resend code
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "A new verification code has been sent 💌",
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Resend Code 🔄",
                        style: TextStyle(
                          color: Color(0xFF959B7D),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Please enter the 6-digit code sent to your email.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
