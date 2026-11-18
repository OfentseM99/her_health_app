
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../theme/design_a.dart';

class JourneyQuestionsScreen extends StatefulWidget {
  final String journey;

  const JourneyQuestionsScreen({
    super.key,
    required this.journey,
  });

  @override
  State<JourneyQuestionsScreen> createState() =>
      _JourneyQuestionsScreenState();
}

class _JourneyQuestionsScreenState extends State<JourneyQuestionsScreen> {
  bool _isSaving = false;

  final Map<String, String?> _answers = {};

  // Identify journeys using their text, not their emoji.
  String get _journeyType {
    final journey = widget.journey.toLowerCase();

    if (journey.contains('pregnancy care')) return 'pregnancy_care';
    if (journey.contains('menstrual health')) return 'menstrual_health';
    if (journey.contains('postpartum recovery')) return 'postpartum_recovery';
    if (journey.contains("general women's health")) return 'general_health';
    if (journey.contains('cosmetic gynecology')) {
      return 'cosmetic_gynecology';
    }

    return '';
  }

  void _setAnswer(String key, String? value) {
    setState(() {
      _answers[key] = value;
    });
  }

  String? _getAnswer(String key) => _answers[key];

  // --------------------------------------------------
  // Reusable selection field
  // --------------------------------------------------

  Widget _dropdown(
    String label,
    String key,
    List<String> options, {
    String hint = 'Select an option',
  }) {
    final selected = _getAnswer(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label(label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: options.contains(selected) ? selected : null,
            hint: Text(
              hint,
              style: DA.body(15, color: DA.quiet),
            ),
            isExpanded: true,
            dropdownColor: DA.surface,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DA.sage,
            ),
            style: DA.body(15),
            decoration: DA.input(),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) => _setAnswer(key, value),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Date selection field
  // --------------------------------------------------

  Widget _dateField(
    String label,
    String key, {
    required bool allowFuture,
    String notSureText = "I don't know",
  }) {
    final selectedDate = _getAnswer(key);
    final isNotSure = selectedDate == notSureText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DA.label(label),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: DA.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DA.quiet.withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: DA.sage,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedDate == null || isNotSure
                        ? 'Choose a date'
                        : selectedDate,
                    style: DA.body(
                      15,
                      color: selectedDate == null || isNotSure
                          ? DA.quiet
                          : DA.muted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final today = DateTime.now();
                    final firstDate = allowFuture
                        ? today
                        : DateTime(1900);
                    final lastDate = allowFuture
                        ? DateTime(2100)
                        : today;

                    DateTime initialDate = today;

                    if (selectedDate != null && !isNotSure) {
                      final parsed = DateTime.tryParse(selectedDate);
                      if (parsed != null) {
                        initialDate = parsed;
                      }
                    }

                    if (initialDate.isBefore(firstDate)) {
                      initialDate = firstDate;
                    }
                    if (initialDate.isAfter(lastDate)) {
                      initialDate = lastDate;
                    }

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                    );

                    if (picked != null) {
                      final formatted =
                          '${picked.year.toString().padLeft(4, '0')}-'
                          '${picked.month.toString().padLeft(2, '0')}-'
                          '${picked.day.toString().padLeft(2, '0')}';

                      _setAnswer(key, formatted);
                    }
                  },
                  child: const Text('Choose'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                _setAnswer(key, notSureText);
              },
              child: Text(notSureText),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Pregnancy Care
  // --------------------------------------------------

  Widget _pregnancyQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          'How many weeks pregnant are you?',
          'weeks_pregnant',
          List.generate(42, (index) {
            final week = index + 1;
            return '$week ${week == 1 ? 'week' : 'weeks'}';
          }),
        ),
        _dropdown(
          'Is this your first pregnancy?',
          'first_pregnancy',
          ['Yes', 'No'],
        ),
        _dropdown(
          'Have you had your first antenatal visit?',
          'had_antenatal_visit',
          ['Yes', 'No'],
        ),
        _dropdown(
          'Do you have any pregnancy complications?',
          'complications',
          ['Yes', 'No', 'Not sure'],
        ),
        _dropdown(
          'Are you taking prenatal vitamins?',
          'taking_vitamins',
          ['Yes', 'No'],
        ),
        _dateField(
          'Estimated due date',
          'due_date',
          allowFuture: true,
          notSureText: "I'm not sure",
        ),
      ],
    );
  }

  // --------------------------------------------------
  // Menstrual Health
  // --------------------------------------------------

  Widget _menstrualQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateField(
          'First day of your last period',
          'last_period',
          allowFuture: false,
        ),
        _dropdown(
          'Average cycle length',
          'cycle_length',
          [
            'Less than 21 days',
            ...List.generate(15, (index) => '${index + 21} days'),
            'More than 35 days',
            "I don't know",
          ],
        ),
        _dropdown(
          'Average period length',
          'period_length',
          [
            ...List.generate(10, (index) => '${index + 1} days'),
            "I don't know",
          ],
        ),
        _dropdown(
          'Do you experience painful cramps?',
          'cramps',
          ['Yes', 'No', 'Sometimes'],
        ),
        _dropdown(
          'Do you experience heavy menstrual flow?',
          'heavy_flow',
          ['Yes', 'No', 'Sometimes', 'Not sure'],
        ),
        _dropdown(
          'Are your periods regular?',
          'regular_periods',
          ['Yes', 'No', 'Sometimes'],
        ),
        _dropdown(
          'Are you using any birth control?',
          'birth_control',
          ['Yes', 'No'],
        ),
      ],
    );
  }

  // --------------------------------------------------
  // Postpartum Recovery
  // --------------------------------------------------

  Widget _postpartumQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateField(
          "Baby's date of birth",
          'baby_birth_date',
          allowFuture: false,
          notSureText: "I don't know",
        ),
        _dropdown(
          'What type of delivery did you have?',
          'delivery_type',
          [
            'Vaginal delivery',
            'Caesarean section (C-section)',
            'Assisted vaginal delivery',
            'Not sure',
          ],
        ),
        _dropdown(
          'Are you breastfeeding?',
          'breastfeeding',
          ['Yes', 'No', 'Partially'],
        ),
        _dropdown(
          'Are you experiencing breastfeeding difficulties?',
          'breastfeeding_difficulty',
          ['Yes', 'No', 'Not applicable', 'Not sure'],
        ),
        _dropdown(
          'How would you describe your sleep quality?',
          'sleep_quality',
          ['Very poor', 'Poor', 'Fair', 'Good'],
        ),
        _dropdown(
          'How has your mood been recently?',
          'mood',
          [
            'Very low',
            'Low',
            'Okay',
            'Good',
            'Prefer not to say',
          ],
        ),
        _dropdown(
          'Have you attended your postpartum check-up?',
          'postpartum_checkup',
          ['Yes', 'No', 'Not yet scheduled'],
        ),
        _dropdown(
          'Do you have any recovery concerns?',
          'concerns',
          ['Yes', 'No', 'Not sure'],
        ),
      ],
    );
  }

  // --------------------------------------------------
  // General Women's Health
  // --------------------------------------------------

  Widget _generalHealthQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          'Height (cm)',
          'height',
          List.generate(25, (index) => '${100 + (index * 5)} cm'),
        ),
        _dropdown(
          'Weight (kg)',
          'weight',
          List.generate(35, (index) => '${30 + (index * 5)} kg'),
        ),
        _dropdown(
          'Do you exercise regularly?',
          'exercise',
          ['Yes', 'No', 'Sometimes'],
        ),
        _dropdown(
          'How often do you drink water?',
          'water_intake',
          [
            'Often',
            'Not often',
            'Inconsistent',
            "I don't pay attention",
          ],
        ),
        _dropdown(
          'Average hours of sleep per night',
          'sleep_hours',
          [
            'Less than 4 hours',
            '4-5 hours',
            '6-7 hours',
            '8-9 hours',
            '10 or more hours',
            "I'm not sure",
          ],
        ),
        _dropdown(
          'Do you have any current health concerns?',
          'health_concerns',
          ['Yes', 'No', 'Not sure'],
        ),
        _dropdown(
          'Do you attend a yearly health check-up?',
          'yearly_checkup',
          ['Yes', 'No', 'Sometimes'],
        ),
        _dateField(
          'When was your last health check-up?',
          'last_checkup',
          allowFuture: false,
          notSureText: "I don't remember",
        ),
        _dropdown(
          'Which area of your health would you like to focus on?',
          'health_category',
          [
            'General wellness',
            'Menstrual health',
            'Hormonal health',
            'Reproductive health',
            'Nutrition and fitness',
            'Mental and emotional wellbeing',
            'Preventive health screenings',
            'Other',
            "I'm not sure",
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------
  // Cosmetic Gynecology
  // --------------------------------------------------

  Widget _cosmeticQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          'What is your main reason for seeking information?',
          'improvement_goal',
          [
            'I want to learn about available options',
            'Appearance-related concerns',
            'Physical discomfort',
            'Changes after pregnancy or childbirth',
            'I have a specific procedure in mind',
            'Other',
            "I'm not sure",
          ],
        ),
        _dropdown(
          'Have you had any previous procedures?',
          'previous_procedures',
          ['Yes', 'No', 'Not sure'],
        ),
        _dropdown(
          'Have you consulted a specialist before?',
          'consulted_specialist',
          ['Yes', 'No'],
        ),
        _dropdown(
          'What kind of support are you interested in?',
          'procedure_interest',
          [
            "I'm exploring my options",
            'I have a specific procedure in mind',
            'I would like a consultation',
            "I'm not sure",
          ],
        ),
        _dropdown(
          'What would you like to understand?',
          'expected_outcome',
          [
            'Available treatment options',
            'Whether a procedure may be suitable for me',
            'Potential benefits and risks',
            'Recovery and aftercare',
            'Costs and consultation information',
            'General information',
            "I'm not sure",
          ],
        ),
        _dropdown(
          'When are you considering seeking a consultation?',
          'procedure_timing',
          [
            'As soon as possible',
            'Within 1-3 months',
            'Within 3-6 months',
            'Within 6-12 months',
            'Just researching',
            "I'm not sure",
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------
  // Build answers for the backend
  // --------------------------------------------------

  Map<String, dynamic> _buildAnswers() {
    final answers = Map<String, dynamic>.from(_answers);

    if (_journeyType == 'postpartum_recovery') {
      final birthDate = answers['baby_birth_date'];

      if (birthDate != null && birthDate != "I don't know") {
        final parsed = DateTime.tryParse(birthDate.toString());

        if (parsed != null) {
          final days = DateTime.now().difference(parsed).inDays;
          answers['weeks_postpartum'] = (days ~/ 7).toString();
        }
      } else {
        answers['weeks_postpartum'] = null;
      }
    }

    return answers;
  }

  // --------------------------------------------------
  // Save and continue
  // --------------------------------------------------

  Future<void> _handleContinue() async {
    final journeyType = _journeyType;

    if (journeyType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unrecognised journey type.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await AuthService.saveHealthJourney(
        journeyType: journeyType,
        answers: _buildAnswers(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // Screen
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget questions;

    switch (_journeyType) {
      case 'pregnancy_care':
        questions = _pregnancyQuestions();
        break;
      case 'menstrual_health':
        questions = _menstrualQuestions();
        break;
      case 'postpartum_recovery':
        questions = _postpartumQuestions();
        break;
      case 'general_health':
        questions = _generalHealthQuestions();
        break;
      case 'cosmetic_gynecology':
        questions = _cosmeticQuestions();
        break;
      default:
        questions = const Text('This health journey could not be identified.');
    }

    return Scaffold(
      backgroundColor: DA.ground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: DA.backButton(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.journey,
                          style: DA.heading(30),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Let's get to know you better so Nia can give you personalised support.",
                          style: DA.body(
                            16,
                            color: DA.muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        questions,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleContinue,
                      style: DA.primary(),
                      child: _isSaving
                          ? DA.buttonSpinner
                          : const Text('Continue'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

