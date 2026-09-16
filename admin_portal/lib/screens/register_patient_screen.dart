import 'package:flutter/material.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedJourney;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _nameController),
            const SizedBox(height: 16),
            const Text('Age', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _ageController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            const Text('Service / Journey', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: 'Pregnancy', child: Text('Pregnancy')),
                DropdownMenuItem(value: 'Postpartum', child: Text('Postpartum')),
                DropdownMenuItem(value: 'Cosmetic Gynaecology', child: Text('Cosmetic Gynaecology')),
                DropdownMenuItem(value: 'Menstrual Health', child: Text('Menstrual Health')),
                DropdownMenuItem(value: 'General Wellness', child: Text('General Wellness')),
              ],
              onChanged: (value) => setState(() => _selectedJourney = value),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient registered (placeholder).')),
                  );
                },
                child: const Text('Register Patient'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}