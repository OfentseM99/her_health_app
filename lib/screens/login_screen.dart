import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../services/auth_service.dart';
import '../services/passkey_service.dart';
import '../theme/design_a.dart';
import 'dashboard_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'health_setup_screen.dart';
import 'register_screen.dart';

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
  bool _deviceLoading = false;
  bool _deviceUnlockAvailable = false;
  bool _nativeBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceUnlock();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkDeviceUnlock() async {
    try {
      bool available = false;
      final nativeBiometric = !kIsWeb;

      if (nativeBiometric) {
        final enabled = await AuthService.isBiometricUnlockEnabled();
        final localAuth = LocalAuthentication();

        if (enabled && await localAuth.isDeviceSupported()) {
          final canCheck = await localAuth.canCheckBiometrics;
          final biometrics = await localAuth.getAvailableBiometrics();
          available = canCheck && biometrics.isNotEmpty;
        }
      } else {
        available = await PasskeyService.isAvailable();
      }

      if (!mounted) return;

      setState(() {
        _deviceUnlockAvailable = available;
        _nativeBiometric = nativeBiometric;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _deviceUnlockAvailable = false;
      });
    }
  }

  Future<void> _goAfterLogin() async {
    final existingJourney = await AuthService.getExistingHealthJourney();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => existingJourney != null
            ? const DashboardScreen()
            : const HealthSetupScreen(),
      ),
    );
  }

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
      await AuthService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      await _goAfterLogin();
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

  Future<void> _handleDeviceUnlock() async {
    if (!_deviceUnlockAvailable) {
      _showError('Device unlock is not available or has not been enabled.');
      return;
    }

    final email = emailController.text.trim();

    if (!_nativeBiometric && email.isEmpty) {
      _showError('Enter your email address first, then use device unlock.');
      return;
    }

    setState(() {
      _deviceLoading = true;
    });

    try {
      if (_nativeBiometric) {
        final authenticated = await AuthService.authenticateBiometricSession();

        if (!authenticated) {
          _showError(
            'Biometric sign-in could not be completed. Please use your password.',
          );
          return;
        }
      } else {
        final options = await AuthService.beginPasskeyLogin(
          email: email,
          portal: 'patient',
        );

        final credentialJson = await PasskeyService.authenticate(
          jsonEncode(options),
        );

        final decoded = jsonDecode(credentialJson);

        if (decoded is! Map) {
          throw AuthException('The device returned an invalid credential.');
        }

        final credential = Map<String, dynamic>.from(decoded);

        await AuthService.finishPasskeyLogin(
          email: email,
          portal: 'patient',
          credential: credential,
        );
      }

      if (!mounted) return;

      await _goAfterLogin();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      final message = e.toString().toLowerCase();

      if (message.contains('notallowed') ||
          message.contains('cancel') ||
          message.contains('usercanceled')) {
        _showError('Device unlock was cancelled.');
      } else {
        _showError(
          'Device unlock failed. You can still sign in with your password.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deviceLoading = false;
        });
      }
    }
  }

  Future<void> _sendToVerification(String email) async {
    try {
      final result = await AuthService.resendCodes(email: email);

      if (!mounted) return;

      _showError(
        'Please verify your account to continue.',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: email,
            phone: (result['phone'] as String?) ?? '',
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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _deviceLoading;

    return Scaffold(
      backgroundColor: DA.ground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              40,
              24,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DA.blush,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        'assets/images/logo/logo.png',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome back',
                    style: DA.heading(32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Good to see you again',
                    style: DA.body(17, color: DA.muted),
                  ),
                  const SizedBox(height: 32),
                  DA.label('Email address'),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.email,
                    ],
                    style: DA.body(16),
                    decoration: DA.input(
                      hint: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 18),
                  DA.label('Password'),
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    autofillHints: const [
                      AutofillHints.password,
                    ],
                    style: DA.body(16),
                    onSubmitted: (_) {
                      if (!busy) {
                        _handleLogin();
                      }
                    },
                    decoration: DA.input(
                      suffix: IconButton(
                        tooltip:
                            hidePassword ? 'Show password' : 'Hide password',
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: DA.sage,
                        ),
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: DA.rose,
                        textStyle: DA.body(
                          14,
                          weight: FontWeight.w700,
                        ),
                        minimumSize: const Size(44, 44),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: DA.primary(),
                    onPressed: busy ? null : _handleLogin,
                    child: _isLoading ? DA.buttonSpinner : const Text('Log in'),
                  ),
                  if (_deviceUnlockAvailable) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: DA.divider,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          child: Text(
                            'or',
                            style: DA.body(
                              14,
                              color: DA.quiet,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: DA.divider,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: DA.outline(),
                      onPressed: busy ? null : _handleDeviceUnlock,
                      icon: _deviceLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DA.rose,
                              ),
                            )
                          : const Icon(
                              Icons.fingerprint_rounded,
                            ),
                      label: Text(
                        _deviceLoading
                            ? 'Checking device...'
                            : 'Use device unlock',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_nativeBiometric
                          ? 'Use your enrolled fingerprint or face recognition.'
                          : 'Use your registered device passkey.'),
                      textAlign: TextAlign.center,
                      style: DA.body(
                        12,
                        color: DA.quiet,
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  Text(
                    "Don't have an account?",
                    textAlign: TextAlign.center,
                    style: DA.body(15, color: DA.muted),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: DA.outline(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
