import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: const Text('Reports'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _stat('Total Patients', '152'),
            _stat('Appointments (This Year)', '421'),
            _stat('Attendance Rate', '91%'),
            _stat('Canceled', '15'),
            const SizedBox(height: 24),
            const Text('Monthly Registrations', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(height: 100, color: Colors.white, child: const Center(child: Text('(Graph)'))),
            const SizedBox(height: 24),
            const Text('Most Common Services', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(height: 100, color: Colors.white, child: const Center(child: Text('(Graph)'))),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.green, fontSize: 18)),
        ],
      ),
    );
  }
}