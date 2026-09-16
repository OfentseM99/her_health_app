import 'package:flutter/material.dart';
import 'invite_staff_screen.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staff = [
      {'name': 'Dr. M. Mbokota', 'role': 'Super Admin'},
      {'name': 'Khanyisa', 'role': 'Receptionist'},
      {'name': 'Dr. P.N Smith', 'role': 'Doctor (obstetrician)'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: const Text('Staff Management'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: staff.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(staff[index]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(staff[index]['role']!, style: const TextStyle(color: Colors.pink)),
                  );
                },
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InviteStaffScreen()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.green),
                label: const Text('Invite Staff', style: TextStyle(color: Colors.green)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}