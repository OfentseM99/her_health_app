import 'package:flutter/material.dart';
import 'quick_secure_login_screen.dart';

class TwoFactorScreen extends StatefulWidget {
  final String name;

  const TwoFactorScreen({super.key, required this.name});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  String _selectedMethod = 'Email';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Protect Patient Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'For the security of your patients, Two-Factor Authentication is required.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose where you\'d like to receive login verification codes.'),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text('Email'),
                  value: 'Email',
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value!),
                ),
                RadioListTile<String>(
                  title: const Text('SMS'),
                  value: 'SMS',
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value!),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuickSecureLoginScreen(name: widget.name),
                      ),
                    );
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}