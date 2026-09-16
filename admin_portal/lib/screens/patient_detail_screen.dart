import 'package:flutter/material.dart';
import 'consultation_notes_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientName;
  final String journey;

  const PatientDetailScreen({super.key, required this.patientName, required this.journey});

  @override
  Widget build(BuildContext context) {
    final links = [
      'Medical Information',
      'Medication',
      'Appointments',
      'Health Journal',
      'Chatbot History',
      'Consultation Notes',
      'Generate QR Code',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: Text(patientName), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Age: 28'),
            const Text('Phone Number'),
            const Text('Email'),
            const SizedBox(height: 16),
            const Text('Current Journey', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(journey, style: const TextStyle(color: Colors.pink)),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: links.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(links[index]),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (links[index] == 'Consultation Notes') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConsultationNotesScreen(patientName: patientName),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${links[index]} screen coming soon.')),
                        );
                      } 
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}