import 'package:flutter/material.dart';
import 'congratulations_screen.dart';

class QuickSecureLoginScreen extends StatefulWidget {
  final String name;

  const QuickSecureLoginScreen({super.key, required this.name});

  @override
  State<QuickSecureLoginScreen> createState() => _QuickSecureLoginScreenState();
}

class _QuickSecureLoginScreenState extends State<QuickSecureLoginScreen> {
  String? _selectedMethod;

  void _goToCongratulations() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CongratulationsScreen(name: widget.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick & Secure Login',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Would you like to enable for quicker access?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                RadioListTile<String>(
                  title: const Text('Fingerprint'),
                  value: 'Fingerprint',
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value),
                ),
                RadioListTile<String>(
                  title: const Text('Face ID'),
                  value: 'Face ID',
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This will only apply to this device.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedMethod == null
                        ? null
                        : _goToCongratulations,
                    child: const Text('Enable'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _goToCongratulations,
                  child: const Text('Skip for now', style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}