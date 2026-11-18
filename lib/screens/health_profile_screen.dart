import 'health_tracking_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/design_a.dart';
import 'journey_questions_screen.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  static const Map<String, List<String>> citiesByProvince = {
    'Eastern Cape': [
      'Bhisho', 'East London', 'Gqeberha (Port Elizabeth)', 'Mthatha',
      'Komani (Queenstown)', 'Makhanda (Grahamstown)', 'Kariega (Uitenhage)',
      'Qonce (King Williamâ€™s Town)', 'Mdantsane', 'Butterworth',
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

  String? selectedProvince;
  String? selectedCity;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final allergiesController = TextEditingController();
  final conditionsController = TextEditingController();
  final medicationsController = TextEditingController();

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

  static const Map<String, String> journeyLabels = {
    'pregnancy_care': 'Pregnancy Care',
    'menstrual_health': 'Menstrual Health',
    'postpartum_recovery': 'Postpartum Recovery',
    'general_health': "General Women's Health",
    'cosmetic_gynecology': 'Cosmetic Gynecology',
  };

  static const Map<String, String> journeyDisplayValues = {
    'pregnancy_care': '🤰 Pregnancy Care',
    'menstrual_health': '🌸 Menstrual Health',
    'postpartum_recovery': '👶 Postpartum Recovery',
    'general_health': "💚 General Women's Health",
    'cosmetic_gynecology': '✨ Cosmetic Gynecology',
  };

  String _email = '';
  DateTime? _dob;
  String? _bloodType;
  String? _journeyType;

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
      final journey = await AuthService.getHealthJourney();

      if (!mounted) return;

      setState(() {
        _email = (me['email'] as String?) ?? '';
        _journeyType = journey?['journey_type'] as String?;

        if (profile is! Map) {
          _hasProfile = false;
          return;
        }

        firstNameController.text = (profile['first_name'] as String?) ?? '';
        lastNameController.text = (profile['last_name'] as String?) ?? '';
        addressController.text = (profile['address'] as String?) ?? '';
        selectedProvince = (profile['province'] as String?) ?? '';
        if (selectedProvince!.isEmpty || !citiesByProvince.containsKey(selectedProvince)) selectedProvince = null;
        selectedCity = (profile['city'] as String?) ?? '';
        if (selectedCity!.isEmpty || selectedProvince == null) {
          selectedCity = null;
        }
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
      'province': selectedProvince,
      'city': selectedCity,
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

  void _changeJourney() {
    final displayJourney = journeyDisplayValues[_journeyType];
    if (displayJourney == null) {
      _showMessage('Please select a health experience first.', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyQuestionsScreen(journey: displayJourney),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : null,
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label(label),
          TextField(
            controller: controller,
            style: DA.body(16),
            decoration: DA.input(hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _provinceField() {
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

  Widget _cityField() {
    final cities = selectedProvince == null
        ? <String>[]
        : List<String>.from(citiesByProvince[selectedProvince]!);

    // Keep an existing saved city visible even if it is not in the
    // common-location list, so saving the profile does not discard it.
    if (selectedCity != null && !cities.contains(selectedCity)) {
      cities.add(selectedCity!);
    }

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
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Text(text, style: DA.heading(19, color: DA.sage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DA.backButton(context),
        const SizedBox(height: 16),
        Text('Health profile', style: DA.heading(30)),
        if (_email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_email, style: DA.body(15, color: DA.muted)),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: DA.rose));
    }

    if (_loadError != null || !_hasProfile) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          _header(),
          const SizedBox(height: 60),
          Text(
            _loadError ?? "No health profile found for this account.",
            textAlign: TextAlign.center,
            style: DA.body(16,
                color: _loadError != null ? DA.rejectedInk : DA.muted),
          ),
        ],
      );
    }

    final dobText = _dob == null
        ? 'Select a date'
        : '${_dob!.day.toString().padLeft(2, '0')}/'
            '${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              _sectionTitle('Personal'),
              _field('First name', firstNameController),
              _field('Last name', lastNameController),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DA.label('Date of birth'),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration: DA.input(
                          suffix: const Icon(Icons.calendar_today_outlined,
                              color: DA.sage),
                        ),
                        child: Text(
                          dobText,
                          style: DA.body(16,
                              color: _dob == null ? DA.quiet : DA.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _sectionTitle('Contact'),
              _field('Street address', addressController),
              _provinceField(),
              _cityField(),
              _field('Emergency contact name', emergencyNameController),
              _field('Emergency contact number', emergencyPhoneController),
              _sectionTitle('Health'),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DA.label('Current health experience'),
                    DropdownButtonFormField<String>(
                      initialValue: journeyLabels.containsKey(_journeyType)
                          ? _journeyType
                          : null,
                      hint: Text('Select', style: DA.body(16, color: DA.quiet)),
                      style: DA.body(16),
                      dropdownColor: DA.surface,
                      borderRadius: BorderRadius.circular(16),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: DA.sage,
                      ),
                      decoration: DA.input(),
                      items: journeyLabels.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _journeyType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: DA.outline(),
                      onPressed: _changeJourney,
                      child: const Text('Update health experience'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You will answer a few questions for the new experience before it replaces your current one.',
                      style: DA.body(13, color: DA.quiet),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(18),
                decoration: DA.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: DA.blush,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.monitor_heart_outlined,
                            color: DA.rose,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health tracking',
                                style: DA.heading(18),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Track symptoms, mood, pain and private journal notes.',
                                style: DA.body(13, color: DA.quiet),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: DA.outline(),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthTrackingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Open health tracking'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DA.label('Blood type'),
                    DropdownButtonFormField<String>(
                      initialValue: _bloodType,
                      hint: Text('Select', style: DA.body(16, color: DA.quiet)),
                      style: DA.body(16),
                      dropdownColor: DA.surface,
                      borderRadius: BorderRadius.circular(16),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: DA.sage),
                      decoration: DA.input(),
                      items: bloodTypes
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _bloodType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              _field('Allergies', allergiesController,
                  hint: 'Separate with commas'),
              _field('Medical conditions', conditionsController,
                  hint: 'Separate with commas'),
              _field('Current medication', medicationsController,
                  hint: 'Separate with commas'),
              const SizedBox(height: 20),
              ElevatedButton(
                style: DA.primary(),
                onPressed: _isSaving ? null : _save,
                child:
                    _isSaving ? DA.buttonSpinner : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
