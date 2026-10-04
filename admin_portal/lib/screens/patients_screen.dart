import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _patients = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.authorizedGet('/patients/all');

      if (response.statusCode == 401 || response.statusCode == 403) {
        await ApiService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to load patients (${response.statusCode}).';
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _patients = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not reach the server.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    final query = _searchQuery.toLowerCase();
    return _patients.where((p) {
      final patient = p as Map<String, dynamic>;
      final firstName = (patient['first_name'] as String? ?? '').toLowerCase();
      final lastName = (patient['last_name'] as String? ?? '').toLowerCase();
      return firstName.contains(query) || lastName.contains(query);
    }).toList();
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final firstName = patient['first_name'] as String? ?? '';
        final lastName = patient['last_name'] as String? ?? '';
        final dob = patient['date_of_birth'] as String?;
        final phone = patient['phone'] as String?;
        final emergencyName = patient['emergency_contact_name'] as String?;
        final emergencyPhone = patient['emergency_contact_phone'] as String?;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$firstName $lastName',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _detailRow('Date of birth', dob ?? 'Not provided'),
              _detailRow('Phone', phone ?? 'Not provided'),
              const Divider(height: 32),
              const Text(
                'Emergency contact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _detailRow('Name', emergencyName ?? 'Not provided'),
              _detailRow('Phone', emergencyPhone ?? 'Not provided'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPatients,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatients,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final patients = _filteredPatients;

    if (patients.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              _searchQuery.isEmpty ? 'No patients yet.' : 'No matches found.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index] as Map<String, dynamic>;
        final firstName = patient['first_name'] as String? ?? '';
        final lastName = patient['last_name'] as String? ?? '';
        final phone = patient['phone'] as String?;
        final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.pink.shade100,
              child: Text(initial, style: const TextStyle(color: Colors.black87)),
            ),
            title: Text('$firstName $lastName'),
            subtitle: Text(phone ?? 'No phone on file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPatientDetails(patient),
          ),
        );
      },
    );
  }
}
