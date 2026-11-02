
import 'package:flutter/material.dart';
import 'chatbot_screen.dart';

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
  // Her Health colours
  static const Color rose = Color(0xFFB04F6C);
  static const Color lightRose = Color(0xFFD9879E);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);

  // Pregnancy Care
  DateTime? dueDate;
  final doctorController = TextEditingController();
  final pregnancyNotesController = TextEditingController();
  final weeksPregnantController = TextEditingController();
  final dueDateController = TextEditingController();
  final pregnancySymptomsController = TextEditingController();
  final pregnancyConcernsController = TextEditingController();
  final firstPregnancyController = TextEditingController();
  final antenatalController = TextEditingController();
  final complicationsController = TextEditingController();
  final vitaminsController = TextEditingController();

  // Menstrual Health
  DateTime? lastPeriod;
  final cycleLengthController = TextEditingController();
  final lastPeriodController = TextEditingController();
  final periodSymptomsController = TextEditingController();
  final flowController = TextEditingController();
  final periodLengthController = TextEditingController();
  final crampsController = TextEditingController();
  final regularController = TextEditingController();
  final birthControlController = TextEditingController();

  // Postpartum Recovery
  final babyAgeController = TextEditingController();
  final deliveryTypeController = TextEditingController();
  final breastfeedingController = TextEditingController();
  final recoveryConcernsController = TextEditingController();
  final postpartumWeeksController = TextEditingController();
  final sleepController = TextEditingController();
  final moodController = TextEditingController();
  final postpartumCheckController = TextEditingController();
  final postpartumConcernController = TextEditingController();

  // General Women's Health
  final healthGoalsController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final exerciseController = TextEditingController();
  final waterController = TextEditingController();
  final sleepHoursController = TextEditingController();
  final healthConcernController = TextEditingController();

  // Cosmetic Gynecology
  final cosmeticQuestionsController = TextEditingController();
  final cosmeticGoalController = TextEditingController();
  final previousProcedureController = TextEditingController();
  final specialistController = TextEditingController();
  final expectedOutcomeController = TextEditingController();

  // Identify the selected journey, with or without emojis.
  String get journeyKey {
    final value = widget.journey.toLowerCase();

    if (value.contains('pregnancy care')) {
      return 'pregnancy';
    } else if (value.contains('menstrual health')) {
      return 'menstrual';
    } else if (value.contains('postpartum recovery')) {
      return 'postpartum';
    } else if (value.contains('general') &&
        value.contains("women's health")) {
      return 'general';
    } else if (value.contains('cosmetic gynecology')) {
      return 'cosmetic';
    }

    return '';
  }

  @override
  void dispose() {
    final controllers = [
      doctorController,
      pregnancyNotesController,
      weeksPregnantController,
      dueDateController,
      pregnancySymptomsController,
      pregnancyConcernsController,
      firstPregnancyController,
      antenatalController,
      complicationsController,
      vitaminsController,
      cycleLengthController,
      lastPeriodController,
      periodSymptomsController,
      flowController,
      periodLengthController,
      crampsController,
      regularController,
      birthControlController,
      babyAgeController,
      deliveryTypeController,
      breastfeedingController,
      recoveryConcernsController,
      postpartumWeeksController,
      sleepController,
      moodController,
      postpartumCheckController,
      postpartumConcernController,
      healthGoalsController,
      heightController,
      weightController,
      exerciseController,
      waterController,
      sleepHoursController,
      healthConcernController,
      cosmeticQuestionsController,
      cosmeticGoalController,
      previousProcedureController,
      specialistController,
      expectedOutcomeController,
    ];

    for (final controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // Show a date picker.
  Future<void> pickDate({
    required DateTime? currentDate,
    required Function(DateTime) onSelected,
  }) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: rose,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: forestGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // Section heading.
  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: blush,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: rose,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable question field.
  Widget buildQuestion(
    String label,
    TextEditingController controller, {
    IconData icon = Icons.edit_outlined,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        onTap: onTap,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          color: forestGreen,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: warmText,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: lightRose,
            size: 21,
          ),
          filled: true,
          fillColor: const Color(0xFFFFFCFB),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: rose,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // Continue to the chatbot only for a recognised journey.
  Widget continueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: rose,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: journeyKey.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatbotScreen(
                      journey: widget.journey,
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text(
          'Continue to Her Health AI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Remove the pregnancy emoji prefix from the displayed title.
  String get displayJourney {
    return widget.journey.replaceFirst(RegExp(r'^🤰\s*'), '');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Keep the existing background image.
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          Container(
            color: Colors.white.withValues(alpha: 0.28),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Go back',
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: rose,
                              size: 27,
                            ),
                          ),
                        ),

                        // Keep the existing logo.
                        Center(
                          child: Image.asset(
                            'assets/images/logo/logo.png',
                            height: 90,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Text(
                            displayJourney,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: forestGreen,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Center(
                          child: Text(
                            'Let’s get to know you better so Her Health AI can give you personalised support.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: warmText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Pregnancy Care questions.
                        if (journeyKey == 'pregnancy') ...[
                          sectionTitle(
                            'Pregnancy Care',
                            Icons.favorite_border,
                          ),
                          buildQuestion(
                            'How many weeks pregnant are you?',
                            weeksPregnantController,
                            icon: Icons.calendar_month_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          buildQuestion(
                            'Is this your first pregnancy?',
                            firstPregnancyController,
                            icon: Icons.person_outline,
                          ),
                          buildQuestion(
                            'Have you had your first antenatal visit?',
                            antenatalController,
                            icon: Icons.medical_services_outlined,
                          ),
                          buildQuestion(
                            'Do you have any pregnancy complications?',
                            complicationsController,
                            icon: Icons.health_and_safety_outlined,
                            maxLines: 2,
                          ),
                          buildQuestion(
                            'Are you taking prenatal vitamins?',
                            vitaminsController,
                            icon: Icons.medication_outlined,
                          ),
                          buildQuestion(
                            'Estimated due date',
                            dueDateController,
                            icon: Icons.event_outlined,
                            readOnly: true,
                            onTap: () => pickDate(
                              currentDate: dueDate,
                              onSelected: (date) {
                                dueDate = date;
                                dueDateController.text = formatDate(date);
                              },
                            ),
                          ),
                        ],

                        // Menstrual Health questions.
                        if (journeyKey == 'menstrual') ...[
                          sectionTitle(
                            'Menstrual Health',
                            Icons.calendar_month_outlined,
                          ),
                          buildQuestion(
                            'First day of your last period',
                            lastPeriodController,
                            icon: Icons.event_outlined,
                            readOnly: true,
                            onTap: () => pickDate(
                              currentDate: lastPeriod,
                              onSelected: (date) {
                                lastPeriod = date;
                                lastPeriodController.text = formatDate(date);
                              },
                            ),
                          ),
                          buildQuestion(
                            'Average cycle length (days)',
                            cycleLengthController,
                            icon: Icons.loop_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          buildQuestion(
                            'Average period length (days)',
                            periodLengthController,
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          buildQuestion(
                            'Do you experience painful cramps?',
                            crampsController,
                            icon: Icons.healing_outlined,
                          ),
                          buildQuestion(
                            'Are your periods regular?',
                            regularController,
                            icon: Icons.sync_outlined,
                          ),
                          buildQuestion(
                            'Are you using any birth control?',
                            birthControlController,
                            icon: Icons.medication_outlined,
                          ),
                        ],

                        // Postpartum Recovery questions.
                        if (journeyKey == 'postpartum') ...[
                          sectionTitle(
                            'Postpartum Recovery',
                            Icons.child_care_outlined,
                          ),
                          buildQuestion(
                            'How many weeks postpartum are you?',
                            postpartumWeeksController,
                            icon: Icons.calendar_month_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          buildQuestion(
                            'Are you breastfeeding?',
                            breastfeedingController,
                            icon: Icons.favorite_border,
                          ),
                          buildQuestion(
                            'How is your sleep quality?',
                            sleepController,
                            icon: Icons.bedtime_outlined,
                          ),
                          buildQuestion(
                            'How has your mood been recently?',
                            moodController,
                            icon: Icons.mood_outlined,
                          ),
                          buildQuestion(
                            'Have you attended your postpartum check-up?',
                            postpartumCheckController,
                            icon: Icons.medical_services_outlined,
                          ),
                          buildQuestion(
                            'Any concerns you would like support with?',
                            postpartumConcernController,
                            icon: Icons.chat_bubble_outline,
                            maxLines: 3,
                          ),
                        ],

                        // General Women's Health questions.
                        if (journeyKey == 'general') ...[
                          sectionTitle(
                            "General Women's Health",
                            Icons.health_and_safety_outlined,
                          ),
                          buildQuestion(
                            'Height (cm)',
                            heightController,
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                          ),
                          buildQuestion(
                            'Weight (kg)',
                            weightController,
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          buildQuestion(
                            'Do you exercise regularly?',
                            exerciseController,
                            icon: Icons.fitness_center_outlined,
                          ),
                          buildQuestion(
                            'How much water do you drink daily?',
                            waterController,
                            icon: Icons.water_drop_outlined,
                          ),
                          buildQuestion(
                            'Average hours of sleep per night',
                            sleepHoursController,
                            icon: Icons.bedtime_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          buildQuestion(
                            'Any current health concerns?',
                            healthConcernController,
                            icon: Icons.health_and_safety_outlined,
                            maxLines: 3,
                          ),
                        ],

                        // Cosmetic Gynecology questions.
                        if (journeyKey == 'cosmetic') ...[
                          sectionTitle(
                            'Cosmetic Gynecology',
                            Icons.spa_outlined,
                          ),
                          buildQuestion(
                            'What would you like to improve?',
                            cosmeticGoalController,
                            icon: Icons.favorite_border,
                            maxLines: 2,
                          ),
                          buildQuestion(
                            'Have you had any previous procedures?',
                            previousProcedureController,
                            icon: Icons.medical_services_outlined,
                            maxLines: 2,
                          ),
                          buildQuestion(
                            'Have you consulted a specialist before?',
                            specialistController,
                            icon: Icons.person_outline,
                          ),
                          buildQuestion(
                            'What outcome are you hoping for?',
                            expectedOutcomeController,
                            icon: Icons.chat_bubble_outline,
                            maxLines: 3,
                          ),
                        ],

                        // Explain when a journey name is not recognised.
                        if (journeyKey.isEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'We could not identify this health journey. Please return to the previous screen and select a journey again.',
                            style: TextStyle(
                              color: warmText,
                              height: 1.5,
                            ),
                          ),
                        ],

                        // Only show Continue for a recognised journey.
                        if (journeyKey.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          continueButton(),
                        ],

                        const SizedBox(height: 12),

                        const Center(
                          child: Text(
                            'Your health journey, supported with care.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: warmText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
