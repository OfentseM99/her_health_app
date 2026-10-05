import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'patient_dashboard_screen.dart';

class JourneyQuestionsScreen extends StatefulWidget {
  final String journey;

  const JourneyQuestionsScreen({
    super.key,
    required this.journey,
  });

  @override
  State<JourneyQuestionsScreen> createState() => _JourneyQuestionsScreenState();
}

class _JourneyQuestionsScreenState extends State<JourneyQuestionsScreen> {
  // ==================================================
  // Pregnancy Care
  // ==================================================

  final TextEditingController weeksPregnantController = TextEditingController();

  String? firstPregnancy;
  String? antenatalVisit;
  String? pregnancyComplications;
  String? prenatalVitamins;

  final TextEditingController dueDateController = TextEditingController();

  // ==================================================
  // Menstrual Health
  // ==================================================

  final TextEditingController lastPeriodController = TextEditingController();

  final TextEditingController cycleLengthController = TextEditingController();

  final TextEditingController periodLengthController = TextEditingController();

  String? painfulCramps;
  String? regularPeriods;
  String? birthControl;

  // ==================================================
  // Postpartum Recovery
  // ==================================================

  final TextEditingController postpartumWeeksController =
      TextEditingController();

  String? breastfeeding;

  String? sleepQuality;

  String? postpartumMood;

  String? postpartumCheckup;

  final TextEditingController postpartumConcernController =
      TextEditingController();

  // ==================================================
  // General Women's Health
  // ==================================================

  final TextEditingController heightController = TextEditingController();

  final TextEditingController weightController = TextEditingController();

  String? exercise;

  final TextEditingController waterController = TextEditingController();

  final TextEditingController sleepHoursController = TextEditingController();

  final TextEditingController healthConcernController = TextEditingController();

  // ==================================================
  // Cosmetic Gynecology
  // ==================================================

  final TextEditingController cosmeticGoalController = TextEditingController();

  String? previousProcedure;

  String? specialist;

  final TextEditingController expectedOutcomeController =
      TextEditingController();

  // ==================================================
  // Dispose Controllers
  // ==================================================

  @override
  void dispose() {
    weeksPregnantController.dispose();
    dueDateController.dispose();

    lastPeriodController.dispose();
    cycleLengthController.dispose();
    periodLengthController.dispose();

    postpartumWeeksController.dispose();
    postpartumConcernController.dispose();

    heightController.dispose();
    weightController.dispose();
    waterController.dispose();
    sleepHoursController.dispose();
    healthConcernController.dispose();

    cosmeticGoalController.dispose();
    expectedOutcomeController.dispose();

    super.dispose();
  }

  // ==================================================
  // Section Title
  // ==================================================

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 15,
        bottom: 15,
      ),
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

  // ==================================================
  // INTEGER FIELD
  // ==================================================

  Widget buildIntegerQuestion(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: _inputDecoration(
          label,
          suffixIcon: const Icon(
            Icons.keyboard_alt_outlined,
            color: Color(0xFF959B7D),
          ),
        ),
      ),
    );
  }

  // ==================================================
  // NORMAL TEXT FIELD
  // ==================================================

  Widget buildQuestion(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        maxLines: 1,
        decoration: _inputDecoration(label),
      ),
    );
  }

  // ==================================================
  // MULTI-LINE TEXT FIELD
  // ==================================================

  Widget buildLongQuestion(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: _inputDecoration(label),
      ),
    );
  }

  // ==================================================
  // YES / NO DROPDOWN
  // ==================================================

  Widget buildYesNoQuestion(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDecoration(
          label,
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF959B7D),
            size: 30,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: "Yes",
            child: Text("Yes"),
          ),
          DropdownMenuItem(
            value: "No",
            child: Text("No"),
          ),
        ],
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

  // ==================================================
  // DROPDOWN WITH CUSTOM OPTIONS
  // ==================================================

  Widget buildDropdownQuestion(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDecoration(
          label,
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF959B7D),
            size: 30,
          ),
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

  // ==================================================
  // INPUT DECORATION
  // ==================================================

  InputDecoration _inputDecoration(
    String label, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF959B7D),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE89CB0),
          width: 2,
        ),
      ),
    );
  }

  // ==================================================
  // DATE PICKER
  // ==================================================

  Future<void> selectDate(
    TextEditingController controller, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE89CB0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF959B7D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    final formattedDate = "${pickedDate.year.toString().padLeft(4, '0')}-"
        "${pickedDate.month.toString().padLeft(2, '0')}-"
        "${pickedDate.day.toString().padLeft(2, '0')}";

    setState(() {
      controller.text = formattedDate;
    });
  }

  // ==================================================
  // DATE FIELD
  // ==================================================

  Widget buildDateQuestion(
    String label,
    TextEditingController controller, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () {
          selectDate(
            controller,
            firstDate: firstDate,
            lastDate: lastDate,
          );
        },
        decoration: _inputDecoration(
          label,
          suffixIcon: const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFF959B7D),
          ),
        ),
      ),
    );
  }

  // ==================================================
  // SAVE JOURNEY
  // ==================================================

  Future<void> saveJourney() async {
    final prefs = await SharedPreferences.getInstance();

    // --------------------------------------------------
    // Save setup completion
    // --------------------------------------------------

    await prefs.setBool(
      'setupCompleted',
      true,
    );

    // --------------------------------------------------
    // Save selected journey
    // --------------------------------------------------

    await prefs.setString(
      'selectedJourney',
      widget.journey,
    );

    // ==================================================
    // PREGNANCY CARE
    // ==================================================

    if (widget.journey == "🤰 Pregnancy Care") {
      await prefs.setString(
        'weeksPregnant',
        weeksPregnantController.text,
      );

      await prefs.setString(
        'firstPregnancy',
        firstPregnancy ?? "",
      );

      await prefs.setString(
        'antenatalVisit',
        antenatalVisit ?? "",
      );

      await prefs.setString(
        'pregnancyComplications',
        pregnancyComplications ?? "",
      );

      await prefs.setString(
        'prenatalVitamins',
        prenatalVitamins ?? "",
      );

      await prefs.setString(
        'dueDate',
        dueDateController.text,
      );
    }

    // ==================================================
    // MENSTRUAL HEALTH
    // ==================================================

    if (widget.journey == "🌸 Menstrual Health") {
      await prefs.setString(
        'lastPeriod',
        lastPeriodController.text,
      );

      await prefs.setString(
        'cycleLength',
        cycleLengthController.text,
      );

      await prefs.setString(
        'periodLength',
        periodLengthController.text,
      );

      await prefs.setString(
        'painfulCramps',
        painfulCramps ?? "",
      );

      await prefs.setString(
        'regularPeriods',
        regularPeriods ?? "",
      );

      await prefs.setString(
        'birthControl',
        birthControl ?? "",
      );
    }

    // ==================================================
    // POSTPARTUM RECOVERY
    // ==================================================

    if (widget.journey == "👶 Postpartum Recovery") {
      await prefs.setString(
        'postpartumWeeks',
        postpartumWeeksController.text,
      );

      await prefs.setString(
        'breastfeeding',
        breastfeeding ?? "",
      );

      await prefs.setString(
        'sleepQuality',
        sleepQuality ?? "",
      );

      await prefs.setString(
        'postpartumMood',
        postpartumMood ?? "",
      );

      await prefs.setString(
        'postpartumCheckup',
        postpartumCheckup ?? "",
      );

      await prefs.setString(
        'postpartumConcern',
        postpartumConcernController.text,
      );
    }

    // ==================================================
    // GENERAL WOMEN'S HEALTH
    // ==================================================

    if (widget.journey == "💚 General Women's Health") {
      await prefs.setString(
        'height',
        heightController.text,
      );

      await prefs.setString(
        'weight',
        weightController.text,
      );

      await prefs.setString(
        'exercise',
        exercise ?? "",
      );

      await prefs.setString(
        'water',
        waterController.text,
      );

      await prefs.setString(
        'sleepHours',
        sleepHoursController.text,
      );

      await prefs.setString(
        'healthConcern',
        healthConcernController.text,
      );
    }

    // ==================================================
    // COSMETIC GYNECOLOGY
    // ==================================================

    if (widget.journey == "✨ Cosmetic Gynecology") {
      await prefs.setString(
        'cosmeticGoal',
        cosmeticGoalController.text,
      );

      await prefs.setString(
        'previousProcedure',
        previousProcedure ?? "",
      );

      await prefs.setString(
        'specialist',
        specialist ?? "",
      );

      await prefs.setString(
        'expectedOutcome',
        expectedOutcomeController.text,
      );
    }

    // ==================================================
    // GO TO DASHBOARD
    // ==================================================

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientDashboardScreen(),
      ),
      (route) => false,
    );
  }

  // ==================================================
  // CONTINUE BUTTON
  // ==================================================

  Widget continueButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE89CB0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: saveJourney,
        child: const Text(
          "Continue to Her Health 🌸",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================
          // BACKGROUND
          // ==================================================

          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // ==================================================
          // OVERLAY
          // ==================================================

          Container(
            color: Colors.white.withValues(alpha: 0.25),
          ),

          // ==================================================
          // MAIN CONTENT
          // ==================================================

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 15,
                      color: Colors.black12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // LOGO
                    // ==================================================

                    Center(
                      child: Image.asset(
                        'assets/images/logo/logo.png',
                        height: 90,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // JOURNEY NAME
                    // ==================================================

                    Center(
                      child: Text(
                        widget.journey,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF959B7D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Center(
                      child: Text(
                        "Let's get to know you better so Her Health can provide personalised support.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // PREGNANCY CARE
                    // ==================================================

                    if (widget.journey == "🤰 Pregnancy Care") ...[
                      sectionTitle("🤰 Pregnancy Care"),
                      buildIntegerQuestion(
                        "🤰 How many weeks pregnant are you?",
                        weeksPregnantController,
                      ),
                      buildYesNoQuestion(
                        "👩 Is this your first pregnancy?",
                        firstPregnancy,
                        (value) {
                          setState(() {
                            firstPregnancy = value;
                          });
                        },
                      ),
                      buildYesNoQuestion(
                        "🏥 Have you had your first antenatal visit?",
                        antenatalVisit,
                        (value) {
                          setState(() {
                            antenatalVisit = value;
                          });
                        },
                      ),
                      buildYesNoQuestion(
                        "🩸 Do you have any pregnancy complications?",
                        pregnancyComplications,
                        (value) {
                          setState(() {
                            pregnancyComplications = value;
                          });
                        },
                      ),
                      buildYesNoQuestion(
                        "💊 Are you taking prenatal vitamins?",
                        prenatalVitamins,
                        (value) {
                          setState(() {
                            prenatalVitamins = value;
                          });
                        },
                      ),
                      buildDateQuestion(
                        "📅 Estimated Due Date",
                        dueDateController,
                        firstDate: now,
                        lastDate: DateTime(
                          now.year + 1,
                          now.month,
                          now.day,
                        ),
                      ),
                    ],

                    // ==================================================
                    // MENSTRUAL HEALTH
                    // ==================================================

                    if (widget.journey == "🌸 Menstrual Health") ...[
                      sectionTitle("🌸 Menstrual Health"),
                      buildDateQuestion(
                        "📅 First day of your last period",
                        lastPeriodController,
                        firstDate: DateTime(1950),
                        lastDate: now,
                      ),
                      buildIntegerQuestion(
                        "🔄 Average cycle length (days)",
                        cycleLengthController,
                      ),
                      buildIntegerQuestion(
                        "🩸 Average period length (days)",
                        periodLengthController,
                      ),
                      buildYesNoQuestion(
                        "😖 Do you experience painful cramps?",
                        painfulCramps,
                        (value) {
                          setState(() {
                            painfulCramps = value;
                          });
                        },
                      ),
                      buildYesNoQuestion(
                        "😊 Are your periods regular?",
                        regularPeriods,
                        (value) {
                          setState(() {
                            regularPeriods = value;
                          });
                        },
                      ),
                      buildYesNoQuestion(
                        "💊 Are you using any birth control?",
                        birthControl,
                        (value) {
                          setState(() {
                            birthControl = value;
                          });
                        },
                      ),
                    ],

                    // ==================================================
                    // POSTPARTUM RECOVERY
                    // ==================================================

                    if (widget.journey == "👶 Postpartum Recovery") ...[
                      sectionTitle("👶 Postpartum Recovery"),
                      buildIntegerQuestion(
                        "🍼 How many weeks postpartum are you?",
                        postpartumWeeksController,
                      ),
                      buildYesNoQuestion(
                        "🤱 Are you breastfeeding?",
                        breastfeeding,
                        (value) {
                          setState(() {
                            breastfeeding = value;
                          });
                        },
                      ),
                      buildDropdownQuestion(
                        "😴 How is your sleep quality?",
                        sleepQuality,
                        const [
                          "Good",
                          "Okay",
                          "Poor",
                        ],
                        (value) {
                          setState(() {
                            sleepQuality = value;
                          });
                        },
                      ),
                      buildDropdownQuestion(
                        "😊 How has your mood been recently?",
                        postpartumMood,
                        const [
                          "Good",
                          "Okay",
                          "Low",
                        ],
                        (value) {
                          setState(() {
                            postpartumMood = value;
                          });
                        },
                      ),
                      buildYesNoQuestion(
                        "🩺 Have you attended your postpartum check-up?",
                        postpartumCheckup,
                        (value) {
                          setState(() {
                            postpartumCheckup = value;
                          });
                        },
                      ),
                      buildLongQuestion(
                        "❤️ Do you have any concerns you'd like support with?",
                        postpartumConcernController,
                      ),
                    ],

                    // ==================================================
                    // GENERAL WOMEN'S HEALTH
                    // ==================================================

                    if (widget.journey == "💚 General Women's Health") ...[
                      sectionTitle("💚 General Women's Health"),
                      buildIntegerQuestion(
                        "📏 Height (cm)",
                        heightController,
                      ),
                      buildIntegerQuestion(
                        "⚖️ Weight (kg)",
                        weightController,
                      ),
                      buildYesNoQuestion(
                        "🏃 Do you exercise regularly?",
                        exercise,
                        (value) {
                          setState(() {
                            exercise = value;
                          });
                        },
                      ),
                      buildIntegerQuestion(
                        "💧 How many glasses of water do you drink daily?",
                        waterController,
                      ),
                      buildIntegerQuestion(
                        "😴 Average hours of sleep per night",
                        sleepHoursController,
                      ),
                      buildLongQuestion(
                        "🩺 Any current health concerns?",
                        healthConcernController,
                      ),
                    ],

                    // ==================================================
                    // COSMETIC GYNECOLOGY
                    // ==================================================

                    if (widget.journey == "✨ Cosmetic Gynecology") ...[
                      sectionTitle("✨ Cosmetic Gynecology"),
                      buildLongQuestion(
                        "💬 What would you like to improve?",
                        cosmeticGoalController,
                      ),
                      buildYesNoQuestion(
                        "📅 Have you had any previous procedures?",
                        previousProcedure,
                        (value) {
                          setState(() {
                            previousProcedure = value;
                          });
                        },
                      ),
                      buildYesNoQuestion(
                        "👩‍⚕️ Have you consulted a specialist before?",
                        specialist,
                        (value) {
                          setState(() {
                            specialist = value;
                          });
                        },
                      ),
                      buildLongQuestion(
                        "⭐ What outcome are you hoping for?",
                        expectedOutcomeController,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ==================================================
                    // CONTINUE
                    // ==================================================

                    continueButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
