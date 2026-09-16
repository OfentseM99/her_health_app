import 'package:flutter/material.dart';

class InviteStaffScreen extends StatefulWidget {
  const InviteStaffScreen({super.key});

  @override
  State<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends State<InviteStaffScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'Receptionist';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: const Text('Invite Staff'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('First Name', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _firstNameController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _lastNameController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _emailController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _phoneController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Receptionist', child: Text('Receptionist')),
                DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
              ],
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation sent (placeholder).')),
                  );
                },
                child: const Text('Send Invitation', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}