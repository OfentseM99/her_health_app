import 'package:flutter/material.dart';
import 'email_verification_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  final TextEditingController emergencyNameController =
      TextEditingController();
  final TextEditingController emergencyPhoneController =
      TextEditingController();

  // Date of birth is now a real date, not free text.
  DateTime? selectedDob;

  // Health fields are now selections, not free text.
  String? selectedBloodType;
  final Set<String> selectedAllergies = {};
  final Set<String> selectedConditions = {};
  final Set<String> selectedMedications = {};

  // "Other" free-text follow-ups, only shown when "Other" is selected.
  final TextEditingController allergyOtherController = TextEditingController();
  final TextEditingController conditionOtherController =
      TextEditingController();
  final TextEditingController medicationOtherController =
      TextEditingController();

  bool _isSubmitting = false;

  static const List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    "I don't know",
  ];

  static const List<String> allergyOptions = [
    'None',
    'Penicillin',
    'Peanuts',
    'Shellfish',
    'Latex',
    'Pollen',
    'Dust',
    'Pet dander',
    'Other',
  ];

  static const List<String> conditionOptions = [
    'None',
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Thyroid disorder',
    'PCOS',
    'Anaemia',
    'Other',
  ];

  static const List<String> medicationOptions = [
    'None',
    'Contraceptive pill',
    'Iron supplements',
    'Antidepressants',
    'Blood pressure medication',
    'Other',
  ];

  Widget inputField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: password,
        decoration: InputDecoration(
          labelText: label,
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

  /// Tap-to-open native date picker. Shows the picked date, never lets the
  /// user free-type a date.
  Widget dateOfBirthField() {
    final displayText = selectedDob == null
        ? ''
        : '${selectedDob!.day.toString().padLeft(2, '0')}/'
            '${selectedDob!.month.toString().padLeft(2, '0')}/'
            '${selectedDob!.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(now.year - 25, now.month, now.day),
            firstDate: DateTime(1920),
            lastDate: now,
            helpText: 'Select date of birth',
          );
          if (picked != null) {
            setState(() {
              selectedDob = picked;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(
              Icons.calendar_today,
              color: Color(0xFF959B7D),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            displayText.isEmpty ? 'Tap to select' : displayText,
            style: TextStyle(
              color: displayText.isEmpty ? Colors.black45 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  /// Single-select dropdown for blood type.
  Widget bloodTypeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: selectedBloodType,
        decoration: InputDecoration(
          labelText: 'Blood Type 🩸',
          prefixIcon: const Icon(Icons.bloodtype, color: Color(0xFF959B7D)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        items: bloodTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedBloodType = value;
          });
        },
      ),
    );
  }

  /// Multi-select chip group. Selecting "Other" reveals a text field for
  /// anything not in the preset list. Selecting "None" clears every other
  /// selection, since they're mutually exclusive.
  Widget multiSelectField({
    required String label,
    required IconData icon,
    required List<String> options,
    required Set<String> selected,
    required TextEditingController otherController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF959B7D), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF959B7D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = selected.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE89CB0).withValues(alpha: 0.3),
                  checkmarkColor: const Color(0xFFE89CB0),
                  onSelected: (value) {
                    setState(() {
                      if (option == 'None') {
                        selected.clear();
                        if (value) selected.add('None');
                      } else {
                        selected.remove('None');
                        if (value) {
                          selected.add(option);
                        } else {
                          selected.remove(option);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (selected.contains('Other')) ...[
              const SizedBox(height: 12),
              TextField(
                controller: otherController,
                decoration: InputDecoration(
                  hintText: 'Please specify',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF959B7D),
        ),
      ),
    );
  }

  /// Turns a chip selection into the final list to send the backend:
  /// "Other" is replaced by whatever was typed in its follow-up field
  /// (or dropped if that field was left empty), every other selection
  /// (including "None") is sent through as-is.
  List<String> _finalizeSelection(
    Set<String> selected,
    TextEditingController otherController,
  ) {
    final result = <String>[];
    for (final item in selected) {
      if (item == 'Other') {
        final custom = otherController.text.trim();
        if (custom.isNotEmpty) {
          result.add(custom);
        }
      } else {
        result.add(item);
      }
    }
    return result;
  }

  Future<void> _handleCreateAccount() async {
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (emailController.text.trim().isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number.');
      return;
    }
    if (passwordController.text.isEmpty) {
      _showError('Please enter a password.');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await AuthService.register(
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text,
        dateOfBirth: selectedDob,
        emergencyContactName: emergencyNameController.text,
        emergencyContactPhone: emergencyPhoneController.text,
        address: addressController.text,
        city: cityController.text,
        bloodType: selectedBloodType,
        allergies: _finalizeSelection(selectedAllergies, allergyOtherController),
        medicalConditions:
            _finalizeSelection(selectedConditions, conditionOtherController),
        currentMedications:
            _finalizeSelection(selectedMedications, medicationOtherController),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            // SIMULATED: these are the real codes the backend generated,
            // shown here because no real email/SMS provider is connected
            // yet. See auth.py's register_user for the full explanation.
            simulatedEmailCode: result['email_code'] as String?,
            simulatedPhoneCode: result['phone_code'] as String?,
          ),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(color: Colors.white.withOpacity(0.25)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Image.asset('assets/images/logo/logo.png', height: 100),
                  const SizedBox(height: 15),
                  const Text(
                    "Create Your Her Health Account 🌸",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF959B7D),
                    ),
                  ),

                  sectionTitle("👤 Personal Information"),

                  inputField("Full Name", Icons.person, nameController),

                  dateOfBirthField(),

                  inputField("Email Address", Icons.email, emailController),

                  inputField("Phone Number", Icons.phone, phoneController),

                  inputField(
                    "Password",
                    Icons.lock,
                    passwordController,
                    password: true,
                  ),

                  inputField(
                    "Confirm Password",
                    Icons.lock_outline,
                    confirmPasswordController,
                    password: true,
                  ),

                  sectionTitle("🏠 Contact Information"),

                  inputField("Street Address", Icons.home, addressController),

                  inputField("City", Icons.location_city, cityController),

                  inputField(
                    "Emergency Contact Name",
                    Icons.contact_phone,
                    emergencyNameController,
                  ),

                  inputField(
                    "Emergency Contact Number",
                    Icons.phone_in_talk,
                    emergencyPhoneController,
                  ),

                  sectionTitle("❤️ Health Information"),

                  bloodTypeField(),

                  multiSelectField(
                    label: 'Allergies ⚠️',
                    icon: Icons.warning,
                    options: allergyOptions,
                    selected: selectedAllergies,
                    otherController: allergyOtherController,
                  ),

                  multiSelectField(
                    label: 'Medical Conditions',
                    icon: Icons.medical_information,
                    options: conditionOptions,
                    selected: selectedConditions,
                    otherController: conditionOtherController,
                  ),

                  multiSelectField(
                    label: 'Current Medication 💊',
                    icon: Icons.medication,
                    options: medicationOptions,
                    selected: selectedMedications,
                    otherController: medicationOtherController,
                  ),

                  const SizedBox(height: 30),

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
                      onPressed: _isSubmitting ? null : _handleCreateAccount,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Create Account 🌸",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
