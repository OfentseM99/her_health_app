import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;

  /// SIMULATED codes, passed through from registration. No real email/SMS
  /// provider is connected yet -- these are shown on-screen (in a clearly
  /// labelled dev-mode banner) purely so the flow can be tested end to
  /// end. Remove this display, and the fields that carry it, once a real
  /// provider is wired up in the backend.
  // Null unless the backend runs with DEV_MODE=true.
  final String? simulatedEmailCode;
  final String? simulatedPhoneCode;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.phone,
    required this.simulatedEmailCode,
    required this.simulatedPhoneCode,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> codeControllers =
      List.generate(6, (index) => TextEditingController());

  // User's choice of verification method. Defaults to email.
  String selectedMethod = 'email';

  bool _isVerifying = false;
  bool _isResending = false;
  String? _currentSimulatedEmailCode;
  String? _currentSimulatedPhoneCode;

  @override
  void initState() {
    super.initState();
    _currentSimulatedEmailCode = widget.simulatedEmailCode;
    _currentSimulatedPhoneCode = widget.simulatedPhoneCode;
  }

  String get _enteredCode => codeControllers.map((c) => c.text).join();

  String get _currentSimulatedCode => selectedMethod == 'email'
      ? (_currentSimulatedEmailCode ?? '')
      : (_currentSimulatedPhoneCode ?? '');

  String get _destination =>
      selectedMethod == 'email' ? widget.email : widget.phone;

  void _clearCodeBoxes() {
    for (final controller in codeControllers) {
      controller.clear();
    }
  }

  Widget methodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
    );
  }

  Widget _methodButton(String method, String label) {
    final isSelected = selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = method;
          _clearCodeBoxes();
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

  Widget codeBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
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

  Future<void> _handleVerify() async {
    final code = _enteredCode;

    if (code.length != 6) {
      _showMessage('Please enter all 6 digits.', isError: true);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await AuthService.verify(
        email: widget.email,
        method: selectedMethod,
        code: code,
      );

      if (!mounted) return;
      _showMessage(
        'Account verified successfully via $selectedMethod 🌸 Please log in.',
      );

      // Verification is done: send the user to the login screen and clear
      // the registration/verification screens from the back stack, so the
      // back button can't return to a finished verification.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
    });

    try {
      final result = await AuthService.resendCodes(email: widget.email);
      if (!mounted) return;
      setState(() {
        _currentSimulatedEmailCode = result['email_code'] as String?;
        _currentSimulatedPhoneCode = result['phone_code'] as String?;
        _clearCodeBoxes();
      });
      _showMessage('New codes generated.');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : null,
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Image.asset('assets/images/logo/logo.png', height: 110),
                  const SizedBox(height: 20),

                  const Text(
                    "Verify Your Account 💌",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Choose how you'd like to verify:",
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),

                  const SizedBox(height: 12),

                  methodToggle(),

                  const SizedBox(height: 20),

                  // Dev-mode banner: only shown when the backend runs with
                  // DEV_MODE=true and actually returned a code.
                  if (_currentSimulatedCode.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 10),
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
                        Text('Code: $_currentSimulatedCode'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    selectedMethod == 'email'
                        ? "Code sent to your email:"
                        : "Code sent to your phone:",
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  Text(
                    _destination,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE89CB0),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) => codeBox(i)),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: 280,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE89CB0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _isVerifying ? null : _handleVerify,
                      child: _isVerifying
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Verify",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _isResending ? null : _handleResend,
                    child: Text(
                      _isResending ? "Sending..." : "Resend Codes 🔄",
                      style: const TextStyle(
                        color: Color(0xFF959B7D),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
