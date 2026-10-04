import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final allergiesController = TextEditingController();
  final conditionsController = TextEditingController();
  final medicationsController = TextEditingController();

  static const List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', "I don't know",
  ];

  String _email = '';
  DateTime? _dob;
  String? _bloodType;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasProfile = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Lists are edited as comma-separated text: "Peanuts, Latex".
  String _joinList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    return '';
  }

  List<String> _splitList(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _orNull(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _load() async {
    try {
      final me = await AuthService.getMe();
      final profile = me['profile'];

      if (!mounted) return;

      setState(() {
        _email = (me['email'] as String?) ?? '';

        if (profile is! Map) {
          _hasProfile = false;
          return;
        }

        firstNameController.text = (profile['first_name'] as String?) ?? '';
        lastNameController.text = (profile['last_name'] as String?) ?? '';
        addressController.text = (profile['address'] as String?) ?? '';
        cityController.text = (profile['city'] as String?) ?? '';
        emergencyNameController.text =
            (profile['emergency_contact_name'] as String?) ?? '';
        emergencyPhoneController.text =
            (profile['emergency_contact_phone'] as String?) ?? '';
        allergiesController.text = _joinList(profile['allergies']);
        conditionsController.text = _joinList(profile['medical_conditions']);
        medicationsController.text = _joinList(profile['current_medications']);

        final dobText = profile['date_of_birth'] as String?;
        _dob = dobText == null ? null : DateTime.tryParse(dobText);

        final blood = profile['blood_type'] as String?;
        _bloodType = bloodTypes.contains(blood) ? blood : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _save() async {
    if (firstNameController.text.trim().isEmpty) {
      _showMessage('First name can\'t be empty.', isError: true);
      return;
    }

    final fields = <String, dynamic>{
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'address': _orNull(addressController.text),
      'city': _orNull(cityController.text),
      'emergency_contact_name': _orNull(emergencyNameController.text),
      'emergency_contact_phone': _orNull(emergencyPhoneController.text),
      'allergies': _splitList(allergiesController.text),
      'medical_conditions': _splitList(conditionsController.text),
      'current_medications': _splitList(medicationsController.text),
    };

    // Only send these when set, so an unset value never wipes stored data.
    if (_bloodType != null) {
      fields['blood_type'] = _bloodType;
    }
    if (_dob != null) {
      final mm = _dob!.month.toString().padLeft(2, '0');
      final dd = _dob!.day.toString().padLeft(2, '0');
      fields['date_of_birth'] = '${_dob!.year}-$mm-$dd';
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await AuthService.updateProfile(fields);
      if (!mounted) return;
      _showMessage('Profile saved 🌸');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : null,
      ),
    );
  }

  Widget _field(String label, IconData icon, TextEditingController controller,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF959B7D)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF959B7D),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE89CB0),
        title: const Text(
          "Health Profile 💗",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.white.withOpacity(0.30)),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (!_hasProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "No health profile found for this account.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final dobText = _dob == null
        ? 'Tap to select'
        : '${_dob!.day.toString().padLeft(2, '0')}/'
            '${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_email.isNotEmpty)
            Text(_email, style: const TextStyle(color: Colors.black54)),

          _sectionTitle("👤 Personal"),
          _field("First Name", Icons.person, firstNameController),
          _field("Last Name", Icons.person_outline, lastNameController),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _pickDob,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: const Icon(Icons.calendar_today,
                      color: Color(0xFF959B7D)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: Text(dobText),
              ),
            ),
          ),

          _sectionTitle("🏠 Contact"),
          _field("Street Address", Icons.home, addressController),
          _field("City", Icons.location_city, cityController),
          _field("Emergency Contact Name", Icons.contact_phone,
              emergencyNameController),
          _field("Emergency Contact Number", Icons.phone_in_talk,
              emergencyPhoneController),

          _sectionTitle("❤️ Health"),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _bloodType,
              decoration: InputDecoration(
                labelText: 'Blood Type 🩸',
                prefixIcon:
                    const Icon(Icons.bloodtype, color: Color(0xFF959B7D)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              items: bloodTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _bloodType = value;
                });
              },
            ),
          ),
          _field("Allergies", Icons.warning, allergiesController,
              hint: "Separate with commas"),
          _field("Medical Conditions", Icons.medical_information,
              conditionsController,
              hint: "Separate with commas"),
          _field("Current Medication", Icons.medication,
              medicationsController,
              hint: "Separate with commas"),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Save Changes 🌸",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
