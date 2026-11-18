import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/api_service.dart';
import '../services/passkey_service.dart';
import '../theme/design_a.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _deviceLoading = false;
  bool _deviceUnlockAvailable = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkDeviceUnlock();
  }

  Future<void> _checkDeviceUnlock() async {
    try {
      bool available = false;

      if (kIsWeb) {
        available = await PasskeyService.isAvailable();
      } else {
        final enabled = await ApiService.isBiometricUnlockEnabled();

        if (enabled) {
          final auth = LocalAuthentication();
          final supported = await auth.isDeviceSupported();
          final biometrics = await auth.getAvailableBiometrics();
          available = supported && biometrics.isNotEmpty;
        }
      }

      if (!mounted) return;

      setState(() {
        _deviceUnlockAvailable = available;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _deviceUnlockAvailable = false;
      });
    }
  }
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await ApiService.login(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      return;
    }

    _openDashboard();
  }

  Future<void> _handleDeviceUnlock() async {
    if (!_deviceUnlockAvailable) {
      setState(() {
        _errorMessage =
            'Device unlock is not available on this device or browser.';
      });
      return;
    }

    setState(() {
      _deviceLoading = true;
      _errorMessage = null;
    });

    try {
      if (!kIsWeb) {
        final authenticated = await ApiService.authenticateBiometricSession();

        if (!mounted) return;

        if (authenticated) {
          _openDashboard();
        } else {
          setState(() {
            _errorMessage =
                'Biometric sign-in could not be completed. Please use your staff password.';
            _deviceUnlockAvailable = false;
          });
        }

        return;
      }

      final email = _emailController.text.trim();

      if (email.isEmpty) {
        setState(() {
          _errorMessage = 'Enter your staff email first, then use device unlock.';
        });
        return;
      }

      final options = await ApiService.beginPasskeyLogin(email: email);

      final credentialJson = await PasskeyService.authenticate(
        jsonEncode(options),
      );

      final decoded = jsonDecode(credentialJson);

      if (decoded is! Map) {
        throw Exception('The device returned an invalid credential.');
      }

      final error = await ApiService.finishPasskeyLogin(
        email: email,
        credential: Map<String, dynamic>.from(decoded),
      );

      if (!mounted) return;

      if (error != null) {
        setState(() {
          _errorMessage = error;
        });
        return;
      }

      _openDashboard();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().toLowerCase();

      setState(() {
        _errorMessage =
            message.contains('notallowed') || message.contains('cancel')
            ? 'Device unlock was cancelled.'
            : 'Device unlock failed. You can still use your password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _deviceLoading = false;
        });
      }
    }
  }
  void _openDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _deviceLoading;

    return Scaffold(
      backgroundColor: DA.ground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                        height: 44,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.spa, size: 44, color: DA.rose),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Admin portal',
                    style: DA.body(15, color: DA.sage, weight: FontWeight.w700),
                  ),

                  const SizedBox(height: 4),

                  Text('Log in', style: DA.heading(32)),

                  const SizedBox(height: 8),

                  Text(
                    'For practice staff only.',
                    style: DA.body(16, color: DA.muted),
                  ),

                  const SizedBox(height: 32),

                  DA.label('Email address'),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: DA.body(16),
                    decoration: DA.input(),
                  ),

                  const SizedBox(height: 18),

                  DA.label('Password'),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    style: DA.body(16),
                    decoration: DA.input(
                      suffix: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: DA.sage,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!busy) {
                        _handleLogin();
                      }
                    },
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DA.rejectedBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: DA.body(
                          14,
                          color: DA.rejectedInk,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  ElevatedButton(
                    style: DA.primary(),
                    onPressed: busy ? null : _handleLogin,
                    child: _isLoading ? DA.buttonSpinner : const Text('Log in'),
                  ),

                  if (_deviceUnlockAvailable) ...[
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(child: Divider(color: DA.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or',
                            style: DA.body(14, color: DA.quiet),
                          ),
                        ),
                        const Expanded(child: Divider(color: DA.divider)),
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
                          : const Icon(Icons.fingerprint_rounded),
                      label: Text(
                        _deviceLoading
                            ? 'Checking device...'
                            : 'Use device unlock',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      (kIsWeb ? 'Use your registered device passkey.' : 'Use your enrolled fingerprint or face recognition.'),
                      textAlign: TextAlign.center,
                      style: DA.body(12, color: DA.quiet),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

