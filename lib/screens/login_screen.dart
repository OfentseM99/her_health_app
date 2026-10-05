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
  // ==================================================
  // Controllers
  // ==================================================

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // ==================================================
  // Security
  // ==================================================

  final LocalAuthentication localAuth = LocalAuthentication();

  bool hidePassword = true;

  bool biometricAvailable = false;

  bool checkingBiometric = true;

  bool isLoading = false;

  // ==================================================
  // INIT
  // ==================================================

  @override
  void initState() {
    super.initState();

    checkBiometricSupport();
  }

  // ==================================================
  // CHECK DEVICE SECURITY
  // ==================================================

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

  // ==================================================
  // NORMAL LOGIN
  // ==================================================

  Future<void> login() async {
    final String email = emailController.text.trim();

    final String password = passwordController.text.trim();

    // Check fields

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter your email and password.",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ==================================================
      // BACKEND AUTHENTICATION
      // ==================================================
      //
      // This is where the real backend/database
      // authentication will eventually be connected.
      //
      // For the prototype we allow the user to continue.
      // ==================================================

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save login state

      await prefs.setBool(
        'isLoggedIn',
        true,
      );

      // Save email

      await prefs.setString(
        'loggedInEmail',
        email,
      );

      // Check whether secure login was previously enabled

      final bool securityEnabled = prefs.getBool('securityEnabled') ?? false;

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // ==================================================
      // IF SECURITY IS ENABLED
      // ==================================================

      if (securityEnabled && biometricAvailable) {
        await authenticateWithDevice();

        return;
      }

      // ==================================================
      // OTHERWISE GO STRAIGHT TO DASHBOARD
      // ==================================================

      goToDashboard();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Something went wrong while logging in.",
          ),
        ),
      );
    }
  }

  // ==================================================
  // DEVICE AUTHENTICATION
  // ==================================================

  Future<void> authenticateWithDevice() async {
    try {
      final List<BiometricType> biometrics =
          await localAuth.getAvailableBiometrics();

      String authenticationName = "device authentication";

      // Face ID / Face authentication

      if (biometrics.contains(BiometricType.face)) {
        authenticationName = "Face ID";
      }

      // Fingerprint

      else if (biometrics.contains(BiometricType.fingerprint)) {
        authenticationName = "fingerprint";
      }

      // Authenticate

      final bool authenticated = await localAuth.authenticate(
        localizedReason: 'Use $authenticationName to open Her Health',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!mounted) return;

      if (authenticated) {
        goToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Authentication cancelled.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Secure login could not be completed.",
          ),
        ),
      );
    }
  }

  // ==================================================
  // ENABLE SECURE LOGIN
  // ==================================================

  Future<void> enableSecureLogin() async {
    try {
      if (!biometricAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your device does not support secure authentication.",
            ),
          ),
        );

        return;
      }

      final bool authenticated = await localAuth.authenticate(
        localizedReason:
            'Confirm your identity to enable secure Her Health login',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) {
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
        'securityEnabled',
        true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Secure login enabled 🔐",
          ),
        ),
      );

      goToDashboard();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Could not enable secure login.",
          ),
        ),
      );
    }
  }

  // ==================================================
  // GO TO DASHBOARD
  // ==================================================

  void goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientDashboardScreen(),
      ),
      (route) => false,
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================
          // BACKGROUND
          // ==================================================

          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // ==================================================
          // SOFT OVERLAY
          // ==================================================

          Container(
            color: Colors.white.withValues(
              alpha: 0.25,
            ),
          ),

          // ==================================================
          // CONTENT
          // ==================================================

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    // ==================================================
                    // LOGO
                    // ==================================================

                    Image.asset(
                      'assets/images/logo/logo.png',
                      height: 120,
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    const Text(
                      "Welcome Back 🌸",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF959B7D),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF959B7D),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // LOGIN CARD
                    // ==================================================

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.92,
                        ),
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
                          // ==================================================
                          // EMAIL
                          // ==================================================

                          buildField(
                            "📧 Email Address",
                            emailController,
                            false,
                          ),

                          // ==================================================
                          // PASSWORD
                          // ==================================================

                          buildField(
                            "🔒 Password",
                            passwordController,
                            true,
                          ),

                          const SizedBox(height: 20),

                          // ==================================================
                          // LOGIN BUTTON
                          // ==================================================

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFE89CB0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    30,
                                  ),
                                ),
                              ),
                              onPressed: isLoading ? null : login,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
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

                          // ==================================================
                          // FORGOT PASSWORD
                          // ==================================================

                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Password recovery will be connected to the backend.",
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF959B7D),
                              ),
                            ),
                          ),

                          // ==================================================
                          // SECURITY SECTION
                          // ==================================================

                          if (!checkingBiometric && biometricAvailable) ...[
                            const Divider(),
                            const SizedBox(height: 15),
                            const Text(
                              "🔐 Secure Login",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF959B7D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Use your phone's fingerprint, Face ID or device PIN to securely access Her Health.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: enableSecureLogin,
                              icon: const Icon(
                                Icons.fingerprint,
                                color: Color(
                                  0xFFE89CB0,
                                ),
                              ),
                              label: const Text(
                                "Enable Secure Login",
                                style: TextStyle(
                                  color: Color(
                                    0xFFE89CB0,
                                  ),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(
                                    0xFFE89CB0,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    30,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 15),

                          const Divider(),

                          const SizedBox(height: 10),

                          // ==================================================
                          // REGISTER
                          // ==================================================

                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 10),

                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFE89CB0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  30,
                                ),
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

  // ==================================================
  // INPUT FIELD
  // ==================================================

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

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }
}
