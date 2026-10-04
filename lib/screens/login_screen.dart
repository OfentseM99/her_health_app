import 'package:flutter/material.dart';
import 'health_setup_screen.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';
import 'chatbot_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.login(email: email, password: password);

      if (!mounted) return;

      // If they've already set up a health journey, skip straight past
      // journey selection and land where they actually left off. A
      // brand-new patient (getExistingHealthJourney returns null) still
      // goes through setup as before.
      final existingJourney = await AuthService.getExistingHealthJourney();

      if (!mounted) return;

      // pushReplacement so the back button doesn't return to the login form.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => existingJourney != null
              ? const ChatbotScreen()
              : const HealthSetupScreen(),
        ),
      );
    } on AuthException catch (e) {
      if (e.isUnverified) {
        await _sendToVerification(email);
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// The account exists but was never verified (e.g. the user closed the
  /// app after registering). Rather than leaving them stuck, generate fresh
  /// codes and take them straight to the verify screen.
  Future<void> _sendToVerification(String email) async {
    try {
      final result = await AuthService.resendCodes(email: email);

      if (!mounted) return;

      _showError('Please verify your account to continue.');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: email,
            phone: (result['phone'] as String?) ?? '',
            // SIMULATED codes -- see auth.py's register_user for details.
            simulatedEmailCode: result['email_code'] as String?,
            simulatedPhoneCode: result['phone_code'] as String?,
          ),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Soft overlay
          Container(color: Colors.white.withOpacity(0.25)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Image.asset('assets/images/logo/logo.png', height: 120),

                    const SizedBox(height: 20),

                    const Text(
                      "Welcome Back 🌸",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF959B7D),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Nobody is identified yet on the login screen, so this
                    // is a general greeting rather than a name.
                    const Text(
                      "Good to see you again ❤️",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF959B7D),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          buildField(
                            "📧 Email Address",
                            emailController,
                            false,
                          ),

                          buildField(
                            "🔒 Password",
                            passwordController,
                            true,
                          ),

                          const SizedBox(height: 20),

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
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Login 🌸",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Color(0xFF959B7D)),
                            ),
                          ),

                          const Divider(),

                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.black54),
                          ),

                          const SizedBox(height: 10),

                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFE89CB0),
                              ),
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
                              "Create Account",
                              style: TextStyle(
                                color: Color(0xFFE89CB0),
                                fontSize: 16,
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
          ),
        ],
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller,
    bool password,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: password ? hidePassword : false,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          suffixIcon: password
              ? IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF959B7D),
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
