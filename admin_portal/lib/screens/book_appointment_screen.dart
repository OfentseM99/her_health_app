import 'package:flutter/material.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? _selectedPatient;
  String? _selectedType;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1F0),
      appBar: AppBar(title: const Text('Book Appointments'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Patient', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Sarah Mokoena', child: Text('Sarah Mokoena')),
                DropdownMenuItem(value: 'Lerato Dube', child: Text('Lerato Dube')),
                DropdownMenuItem(value: 'Nomsa Khumalo', child: Text('Nomsa Khumalo')),
              ],
              onChanged: (value) => setState(() => _selectedPatient = value),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
              },
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
              onTap: () async {
                await showTimePicker(context: context, initialTime: TimeOfDay.now());
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Appointment Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Consultation', child: Text('Consultation')),
                DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                DropdownMenuItem(value: 'Procedure', child: Text('Procedure')),
              ],
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  if (_selectedPatient == null || _selectedType == null) {
                    ScaffoldMessenger.of(context).showSnackBar( 
                    const SnackBar(content: Text('Please select a patient and appointment type.')),
                  );
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment booked for $_selectedPatient ($_selectedType).')),
                );
                },
                child: const Text('Book Appointment', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}