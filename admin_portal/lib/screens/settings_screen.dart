import 'package:flutter/material.dart';
import 'staff_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'My Profile',
      'Clinic Information',
      'Staff Management',
      'Notifications',
      'Security',
      'Backup & Recovery',
      'Audit Logs',
      'Logout',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(items[index]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (items[index] == 'Staff Management') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StaffManagementScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${items[index]} screen coming soon.')),
                );
              }
            },
          );
        },
      ),
    );
  }
}