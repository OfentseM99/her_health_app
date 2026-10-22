import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'patient_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const rose = Color(0xFFB04F6C);
  static const blushPink = Color(0xFFF6DCE2);
  static const forestGreen = Color(0xFF2F3A2A);
  static const warmText = Color(0xFF5E5652);
  static const cardBorder = Color(0xFFEADFDB);
  static const sageGreen = Color(0xFF6E7B5F);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LocalAuthentication localAuth = LocalAuthentication();

  bool hidePassword = true;
  bool biometricAvailable = false;
  bool checkingBiometric = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    startSecureLoginCheck();
  }

  Future<void> startSecureLoginCheck() async {
    await checkBiometricSupport();

    if (!mounted) return;

    if (biometricAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          authenticateWithDevice();
        }
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> checkBiometricSupport() async {
    try {
      final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      final bool deviceSupported = await localAuth.isDeviceSupported();

      if (!mounted) return;

      setState(() {
        biometricAvailable = canCheckBiometrics || deviceSupported;
        checkingBiometric = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        biometricAvailable = false;
        checkingBiometric = false;
      });
    }
  }

  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Prototype only: real backend authentication is not connected.
      await prefs.setString('loggedInEmail', email);
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      goToDashboard();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Something went wrong while logging in.');
    }
  }

  Future<void> authenticateWithDevice() async {
    try {
      final List<BiometricType> biometrics =
          await localAuth.getAvailableBiometrics();

      String authenticationName = 'device authentication';

      if (biometrics.contains(BiometricType.face)) {
        authenticationName = 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        authenticationName = 'your fingerprint';
      }

      final bool authenticated = await localAuth.authenticate(
        localizedReason: 'Use $authenticationName to open Her Health',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!mounted) return;

      if (authenticated) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setBool('isLoggedIn', true);

        if (!mounted) return;

        goToDashboard();
      } else {
        _showMessage('Authentication cancelled.');
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Secure login could not be completed.');
    }
  }

  void goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientDashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: password && hidePassword,
        keyboardType:
            password ? TextInputType.text : TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: rose),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          suffixIcon: password
              ? IconButton(
                  tooltip: hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: sageGreen,
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: rose, width: 2),
          ),
        ),
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
            color: Colors.white.withValues(alpha: 0.25),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo/logo.png',
                        height: 110,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your wellness journey continues here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: warmText,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: cardBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Log in to your account',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: forestGreen,
                              ),
                            ),
                            const SizedBox(height: 20),
                            buildField(
                              'Email Address',
                              Icons.email_outlined,
                              emailController,
                            ),
                            buildField(
                              'Password',
                              Icons.lock_outline,
                              passwordController,
                              password: true,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showMessage(
                                    'Password recovery will be connected to the backend.',
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: rose),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
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
                                onPressed: isLoading ? null : login,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: cardBorder),
                            const SizedBox(height: 18),
                            const SizedBox(height: 24),
                            const Text(
                              "Don't have an account?",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: warmText),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: rose,
                                side: const BorderSide(color: rose),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
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
          ),
        ],
      ),
    );
  }
}
