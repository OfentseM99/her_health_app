import 'package:flutter/material.dart';

class ConsultationNotesScreen extends StatefulWidget {
  final String patientName;

  const ConsultationNotesScreen({super.key, required this.patientName});

  @override
  State<ConsultationNotesScreen> createState() => _ConsultationNotesScreenState();
}

class _ConsultationNotesScreenState extends State<ConsultationNotesScreen> {
  final _diagnosisController = TextEditingController();
  final _medicationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: const Text('Consultation Notes'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patient', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.patientName),
            const SizedBox(height: 16),
            const Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _diagnosisController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Medication', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _medicationController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Doctor\'s Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Follow-up Date', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Consultation saved (placeholder — real save comes once backend is connected).')),
                  );
                },
                child: const Text('Save Consultation', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}