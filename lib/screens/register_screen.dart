import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'email_verification_screen.dart';
import '../services/auth_service.dart';
import '../theme/design_a.dart';
import 'privacy_notice.dart';

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
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  final TextEditingController addressController = TextEditingController();
  String? selectedProvince;
  String? selectedCity;

  final TextEditingController emergencyNameController = TextEditingController();
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

  // The patient must accept the privacy notice to register (POPIA consent).
  bool _acceptedPrivacy = false;

  static const Map<String, List<String>> citiesByProvince = {
    'Eastern Cape': [
      'Bhisho', 'East London', 'Gqeberha (Port Elizabeth)', 'Mthatha',
      'Komani (Queenstown)', 'Makhanda (Grahamstown)', 'Kariega (Uitenhage)',
      'Qonce (King William’s Town)', 'Mdantsane', 'Butterworth',
      'Cradock', 'Graaff-Reinet',
    ],
    'Free State': [
      'Bloemfontein', 'Welkom', 'Bethlehem', 'Kroonstad', 'Sasolburg',
      'Parys', 'Harrismith', 'Phuthaditjhaba', 'Virginia', 'Bothaville',
    ],
    'Gauteng': [
      'Johannesburg', 'Pretoria (Tshwane)', 'Ekurhuleni', 'Kempton Park',
      'Benoni', 'Boksburg', 'Germiston', 'Soweto', 'Midrand', 'Sandton',
      'Roodepoort', 'Randburg', 'Centurion', 'Vereeniging',
      'Vanderbijlpark', 'Krugersdorp', 'Springs', 'Nigel', 'Alberton',
    ],
    'KwaZulu-Natal': [
      'Durban (eThekwini)', 'Pietermaritzburg', 'Richards Bay', 'Newcastle',
      'Ladysmith', 'Port Shepstone', 'Empangeni', 'Ballito', 'Pinetown',
      'Amanzimtoti', 'Ulundi', 'Kokstad',
    ],
    'Limpopo': [
      'Polokwane', 'Tzaneen', 'Thohoyandou', 'Makhado (Louis Trichardt)',
      'Musina', 'Giyani', 'Lephalale', 'Mokopane', 'Bela-Bela',
      'Modimolle', 'Phalaborwa', 'Burgersfort',
    ],
    'Mpumalanga': [
      'Mbombela (Nelspruit)', 'Middelburg', 'Secunda', 'eMalahleni (Witbank)',
      'Standerton', 'Ermelo', 'White River', 'Barberton', 'Hazyview',
      'Malelane', 'Komatipoort', 'Sabie',
    ],
    'Northern Cape': [
      'Kimberley', 'Upington', 'Kathu', 'Kuruman', 'De Aar', 'Springbok',
      'Postmasburg', 'Prieska', 'Jan Kempdorp', 'Colesberg',
    ],
    'North West': [
      'Mahikeng', 'Rustenburg', 'Potchefstroom', 'Klerksdorp', 'Brits',
      'Vryburg', 'Lichtenburg', 'Zeerust', 'Hartbeespoort', 'Orkney',
      'Stilfontein', 'Mogwase',
    ],
    'Western Cape': [
      'Cape Town', 'Stellenbosch', 'Paarl', 'George', 'Worcester',
      'Knysna', 'Mossel Bay', 'Oudtshoorn', 'Hermanus', 'Swellendam',
      'Malmesbury', 'Somerset West', 'Bellville',
    ],
  };
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
    TextEditingController controller, {
    bool password = false,
    bool? obscurePassword,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label(label),
          TextField(
            controller: controller,
            obscureText: password ? (obscurePassword ?? true) : false,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: DA.body(16),
            decoration: DA.input(
              suffix: password
                  ? IconButton(
                      tooltip: (obscurePassword ?? true)
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        (obscurePassword ?? true)
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: DA.sage,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label('Date of birth'),
          InkWell(
            borderRadius: BorderRadius.circular(16),
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
              decoration: DA.input(
                suffix:
                    const Icon(Icons.calendar_today_outlined, color: DA.sage),
              ),
              child: Text(
                displayText.isEmpty ? 'Select a date' : displayText,
                style:
                    DA.body(16, color: displayText.isEmpty ? DA.quiet : DA.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget provinceField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label('Province'),
          DropdownButtonFormField<String>(
            initialValue: selectedProvince,
            hint: Text('Select province', style: DA.body(16, color: DA.quiet)),
            style: DA.body(16),
            dropdownColor: DA.surface,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: DA.sage),
            decoration: DA.input(),
            items: citiesByProvince.keys
                .map((province) => DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedProvince = value;
                selectedCity = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget cityField() {
    final cities = selectedProvince == null
        ? <String>[]
        : citiesByProvince[selectedProvince]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label('City'),
          DropdownButtonFormField<String>(
            initialValue: selectedCity,
            hint: Text(
              selectedProvince == null ? 'Select a province first' : 'Select city',
              style: DA.body(16, color: DA.quiet),
            ),
            style: DA.body(16),
            dropdownColor: DA.surface,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: DA.sage),
            decoration: DA.input(),
            items: cities
                .map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    ))
                .toList(),
            onChanged: selectedProvince == null
                ? null
                : (value) {
                    setState(() {
                      selectedCity = value;
                    });
                  },
          ),
        ],
      ),
    );
  }
  /// Single-select dropdown for blood type.
  Widget bloodTypeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label('Blood type'),
          DropdownButtonFormField<String>(
            initialValue: selectedBloodType,
            hint: Text('Select', style: DA.body(16, color: DA.quiet)),
            style: DA.body(16),
            dropdownColor: DA.surface,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: DA.sage),
            decoration: DA.input(),
            items: bloodTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedBloodType = value;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Multi-select chip group. Selecting "Other" reveals a text field for
  /// anything not in the preset list. Selecting "None" clears every other
  /// selection, since they're mutually exclusive.
  Widget multiSelectField({
    required String label,
    required List<String> options,
    required Set<String> selected,
    required TextEditingController otherController,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(label, style: DA.body(14, weight: FontWeight.w700)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: DA.ink,
                labelStyle: DA.body(
                  14,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                backgroundColor: DA.surface,
                selectedColor: DA.blush,
                side: BorderSide(
                    color: isSelected ? DA.rose : DA.border, width: 1.5),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
              style: DA.body(16),
              decoration: DA.input(hint: 'Please specify'),
            ),
          ],
        ],
      ),
    );
  }

  Widget sectionTitle(String text, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: DA.heading(19, color: DA.sage)),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: DA.body(14, color: DA.quiet)),
          ],
        ],
      ),
    );
  }

  /// Turns a chip selection into the final list to send the backend:
  /// "Other" is replaced by whatever was typed in its follow-up field
  /// (or dropped if that field was left empty), every other selection
  /// (including "None") is sent through as-is.
  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[^A-Za-z0-9]'));
  }

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
    if (!RegExp(r'^\d+$').hasMatch(phoneController.text.trim())) {
      _showError('Phone number must contain digits only.');
      return;
    }
    if (selectedProvince == null) {
      _showError('Please select your province.');
      return;
    }
    if (selectedCity == null) {
      _showError('Please select your city.');
      return;
    }
    if (emergencyPhoneController.text.trim().isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(emergencyPhoneController.text.trim())) {
      _showError('Emergency contact number must contain digits only.');
      return;
    }
    if (passwordController.text.isEmpty) {
      _showError('Please enter a password.');
      return;
    }
    if (!_isStrongPassword(passwordController.text)) {
      _showError(
        'Use at least 8 characters with uppercase, lowercase, a number and a special character.',
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    if (!_acceptedPrivacy) {
      _showError(
          'Please read and accept the privacy notice to create your account.');
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
        province: selectedProvince,
        city: selectedCity,
        bloodType: selectedBloodType,
        allergies:
            _finalizeSelection(selectedAllergies, allergyOtherController),
        medicalConditions:
            _finalizeSelection(selectedConditions, conditionOtherController),
        currentMedications:
            _finalizeSelection(selectedMedications, medicationOtherController),
        acceptedPrivacy: _acceptedPrivacy,
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
      backgroundColor: DA.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DA.backButton(context),
                  ),
                  const SizedBox(height: 16),
                  Text('Create your account', style: DA.heading(30)),
                  const SizedBox(height: 8),
                  Text(
                    'Start your Her Health journey.',
                    style: DA.body(16, color: DA.muted),
                  ),
                  sectionTitle('Personal information'),
                  inputField('Full name', nameController),
                  dateOfBirthField(),
                  inputField('Email address', emailController,
                      keyboardType: TextInputType.emailAddress),
                  inputField('Phone number', phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  inputField(
                    'Password',
                    passwordController,
                    password: true,
                    obscurePassword: _hidePassword,
                    onTogglePassword: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                  ),
                  inputField(
                    'Confirm password',
                    confirmPasswordController,
                    password: true,
                    obscurePassword: _hideConfirmPassword,
                    onTogglePassword: () {
                      setState(() {
                        _hideConfirmPassword = !_hideConfirmPassword;
                      });
                    },
                  ),
                  Text(
                    '8+ characters • Uppercase • Lowercase • Number • Special character',
                    style: DA.body(13, color: DA.quiet),
                  ),
                  const SizedBox(height: 8),
                  sectionTitle('Contact information'),
                  inputField('Street address', addressController),
                  provinceField(),
                  cityField(),
                  inputField('Emergency contact name', emergencyNameController),
                  inputField(
                      'Emergency contact number', emergencyPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  sectionTitle('Health information', note: 'Optional'),
                  bloodTypeField(),
                  multiSelectField(
                    label: 'Allergies',
                    options: allergyOptions,
                    selected: selectedAllergies,
                    otherController: allergyOtherController,
                  ),
                  multiSelectField(
                    label: 'Medical conditions',
                    options: conditionOptions,
                    selected: selectedConditions,
                    otherController: conditionOtherController,
                  ),
                  multiSelectField(
                    label: 'Current medication',
                    options: medicationOptions,
                    selected: selectedMedications,
                    otherController: medicationOtherController,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
                    decoration: DA.card(
                      color: _acceptedPrivacy ? DA.blush : DA.surface,
                      edge: _acceptedPrivacy ? DA.rose : DA.border,
                      radius: 16,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _acceptedPrivacy,
                          activeColor: DA.rose,
                          side: const BorderSide(
                              color: Color(0xFFC9BDB8), width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          onChanged: (value) {
                            setState(() {
                              _acceptedPrivacy = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('I have read and agree to the ',
                                  style: DA.body(14)),
                              InkWell(
                                onTap: () => showPrivacyNotice(context),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'privacy notice',
                                    style: DA
                                        .body(14,
                                            color: DA.rose,
                                            weight: FontWeight.w700)
                                        .copyWith(
                                            decoration:
                                                TextDecoration.underline),
                                  ),
                                ),
                              ),
                              Text('.', style: DA.body(14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: DA.primary(),
                    onPressed: _isSubmitting ? null : _handleCreateAccount,
                    child: _isSubmitting
                        ? DA.buttonSpinner
                        : const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
