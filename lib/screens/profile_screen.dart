import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  static const Color rose = Color(0xFFB04F6C);
  static const Color sage = Color(0xFF6E7B5F);
  static const Color forest = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color border = Color(0xFFEADFDB);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    _name.text = prefs.getString('profile_full_name') ?? '';
    _dob.text = prefs.getString('profile_dob') ?? '';
    _email.text = prefs.getString('profile_email') ??
        prefs.getString('loggedInEmail') ??
        '';
    _phone.text = prefs.getString('profile_phone') ?? '';
    _address.text = prefs.getString('profile_address') ?? '';
    _city.text = prefs.getString('profile_city') ?? '';
    _emergencyName.text = prefs.getString('profile_emergency_name') ?? '';
    _emergencyPhone.text = prefs.getString('profile_emergency_phone') ?? '';

    final imagePath = prefs.getString('profile_image_path');
    if (imagePath != null && await File(imagePath).exists()) {
      _profileImage = File(imagePath);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('profile_full_name', _name.text.trim());
      await prefs.setString('profile_dob', _dob.text.trim());
      await prefs.setString('profile_email', _email.text.trim());
      await prefs.setString('profile_phone', _phone.text.trim());
      await prefs.setString('profile_address', _address.text.trim());
      await prefs.setString('profile_city', _city.text.trim());
      await prefs.setString(
        'profile_emergency_name',
        _emergencyName.text.trim(),
      );
      await prefs.setString(
        'profile_emergency_phone',
        _emergencyPhone.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your profile.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseProfilePhoto() async {
    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (selectedImage == null || !mounted) return;

      final appDirectory = await getApplicationDocumentsDirectory();
      final extension = selectedImage.name.contains('.')
          ? selectedImage.name.split('.').last
          : 'jpg';

      final savedImage = await File(selectedImage.path).copy(
        '${appDirectory.path}/profile_photo.$extension',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);

      if (!mounted) return;
      setState(() => _profileImage = savedImage);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select the profile photo.')),
      );
    }
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 18, now.month, now.day);

    final match =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(_dob.text.trim());

    if (match != null) {
      initial = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your date of birth',
    );

    if (selected != null) {
      setState(() {
        _dob.text =
            '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon, color: sage),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: rose, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: rose),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: forest,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F3),
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: Colors.white,
        foregroundColor: forest,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: rose))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 47,
                          backgroundColor: const Color(0xFFF6DCE2),
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person_rounded,
                                  size: 52, color: rose)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _chooseProfilePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Add profile photo'),
                        ),
                        const Text(
                          'Keep your personal details up to date.',
                          style: TextStyle(color: warmText),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _section(
                    'Personal details',
                    Icons.person_outline,
                    [
                      _field(
                        'Full name',
                        _name,
                        icon: Icons.badge_outlined,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter your name'
                                : null,
                      ),
                      _field(
                        'Date of birth',
                        _dob,
                        icon: Icons.calendar_month_outlined,
                        readOnly: true,
                        onTap: _chooseDate,
                      ),
                      _field(
                        'Email address',
                        _email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      _field(
                        'Phone number',
                        _phone,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _field(
                        'Street address',
                        _address,
                        icon: Icons.home_outlined,
                      ),
                      _field(
                        'City or town',
                        _city,
                        icon: Icons.location_city_outlined,
                      ),
                    ],
                  ),
                  _section(
                    'Emergency contact',
                    Icons.contact_phone_outlined,
                    [
                      _field(
                        'Contact name',
                        _emergencyName,
                        icon: Icons.person_outline,
                      ),
                      _field(
                        'Contact phone number',
                        _emergencyPhone,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your profile details are saved locally on this device.',
                    style: TextStyle(color: warmText, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
