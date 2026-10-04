import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final List<TextEditingController> codeControllers =
      List.generate(6, (index) => TextEditingController());

  String selectedMethod = 'email';
  bool _codeRequested = false;
  bool _isRequesting = false;
  bool _isResetting = false;
  bool _hidePassword = true;

  String? _phoneForDisplay;
  String? _simulatedCode;

  String get _enteredCode => codeControllers.map((c) => c.text).join();

  Future<void> _handleRequestCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    try {
      final result = await AuthService.requestPasswordReset(
        email: email,
        method: selectedMethod,
      );

      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _simulatedCode = result['reset_code'] as String?;
        _phoneForDisplay = result['phone'] as String?;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final code = _enteredCode;

    if (code.length != 6) {
      _showError('Please enter all 6 digits.');
      return;
    }
    if (newPasswordController.text.isEmpty) {
      _showError('Please enter a new password.');
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() {
      _isResetting = true;
    });

    try {
      await AuthService.resetPassword(
        email: emailController.text.trim(),
        code: code,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in. 🌸'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  Widget _methodButton(String method, String label) {
    final isSelected = selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE89CB0) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF959B7D),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _codeBox(int index) {
    return SizedBox(
      width: 42,
      height: 52,
      child: TextField(
        controller: codeControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }
        },
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
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
          Container(color: Colors.white.withOpacity(0.25)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Image.asset('assets/images/logo/logo.png', height: 100),
                  const SizedBox(height: 20),
                  const Text(
                    "Reset Your Password 🌸",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF959B7D),
                    ),
                  ),
                  const SizedBox(height: 25),

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
                        TextField(
                          controller: emailController,
                          enabled: !_codeRequested,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        if (!_codeRequested) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Send the code by:",
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _methodButton('email', 'Email 📧'),
                                _methodButton('phone', 'Phone 📱'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE89CB0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed:
                                  _isRequesting ? null : _handleRequestCode,
                              child: _isRequesting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Send Reset Code",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],

                        if (_codeRequested) ...[
                          const SizedBox(height: 20),

                          // Dev-mode banner: only shown when the backend runs
                          // with DEV_MODE=true and actually returned a code.
                          if (_simulatedCode != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              border: Border.all(color: Colors.amber.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🚧 Dev mode -- no real email or SMS is sent yet.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  selectedMethod == 'email'
                                      ? 'Code: $_simulatedCode'
                                      : 'Code (sent to $_phoneForDisplay): $_simulatedCode',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children:
                                List.generate(6, (i) => _codeBox(i)),
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: newPasswordController,
                            obscureText: _hidePassword,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF959B7D),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _hidePassword = !_hidePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: _hidePassword,
                            decoration: InputDecoration(
                              labelText: "Confirm New Password",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE89CB0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed:
                                  _isResetting ? null : _handleResetPassword,
                              child: _isResetting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Reset Password",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _codeRequested = false;
                              });
                            },
                            child: const Text(
                              "Use a different email or method",
                              style: TextStyle(color: Color(0xFF959B7D)),
                            ),
                          ),
                        ],
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
