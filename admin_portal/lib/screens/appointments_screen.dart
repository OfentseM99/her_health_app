import 'package:flutter/material.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = [
      {'time': '08:00', 'name': 'Sarah', 'status': 'Attended', 'color': Colors.green},
      {'time': '09:30', 'name': 'Thando', 'status': 'Postponed', 'color': Colors.orange},
      {'time': '11:00', 'name': 'Nomsa', 'status': 'Cancelled', 'color': Colors.red},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: const Text('Appointments'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Upcoming, Completed, and Cancelled appointments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appt = appointments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Text(appt['time'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(appt['name'] as String),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 12, color: appt['color'] as Color),
                          const SizedBox(width: 6),
                          Text(appt['status'] as String),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.green),
                label: const Text('Book Appointment', style: TextStyle(color: Colors.green)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}