import 'package:flutter/material.dart';
import 'chatbot_screen.dart';

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

  DateTime? dueDate;

  String? pregnancyTrimester;
  String? pregnancyRisk;

  final TextEditingController doctorController = TextEditingController();

  final TextEditingController pregnancyNotesController =
      TextEditingController();

  final TextEditingController weeksPregnantController = TextEditingController();

  final TextEditingController dueDateController = TextEditingController();

  final TextEditingController pregnancySymptomsController =
      TextEditingController();

  final TextEditingController pregnancyConcernsController =
      TextEditingController();

  final TextEditingController firstPregnancyController =
      TextEditingController();

  final TextEditingController antenatalController = TextEditingController();

  final TextEditingController complicationsController = TextEditingController();

  final TextEditingController vitaminsController = TextEditingController();

  // ==================================================
  // Menstrual Health
  // ==================================================

  DateTime? lastPeriod;

  int cycleLength = 28;
  int periodLength = 5;

  bool irregularPeriods = false;
  bool severePain = false;

  final TextEditingController cycleLengthController = TextEditingController();

  final TextEditingController lastPeriodController = TextEditingController();

  final TextEditingController periodSymptomsController =
      TextEditingController();

  final TextEditingController flowController = TextEditingController();

  final TextEditingController periodLengthController = TextEditingController();

  final TextEditingController crampsController = TextEditingController();

  final TextEditingController regularController = TextEditingController();

  final TextEditingController birthControlController = TextEditingController();

  // ==================================================
  // Postpartum Recovery
  // ==================================================

  DateTime? babyBirthDate;

  String? deliveryType;

  bool breastfeeding = false;

  final TextEditingController postpartumNotesController =
      TextEditingController();

  final TextEditingController babyAgeController = TextEditingController();

  final TextEditingController deliveryTypeController = TextEditingController();

  final TextEditingController breastfeedingController = TextEditingController();

  final TextEditingController recoveryConcernsController =
      TextEditingController();

  final TextEditingController postpartumWeeksController =
      TextEditingController();

  final TextEditingController sleepController = TextEditingController();

  final TextEditingController moodController = TextEditingController();

  final TextEditingController postpartumCheckController =
      TextEditingController();

  final TextEditingController postpartumConcernController =
      TextEditingController();

  // ==================================================
  // General Women's Health
  // ==================================================

  bool yearlyCheckup = false;
  bool papSmear = false;
  bool breastExam = false;

  final TextEditingController healthGoalsController = TextEditingController();

  final TextEditingController heightController = TextEditingController();

  final TextEditingController weightController = TextEditingController();

  final TextEditingController exerciseController = TextEditingController();

  final TextEditingController waterController = TextEditingController();

  final TextEditingController sleepHoursController = TextEditingController();

  final TextEditingController healthConcernController = TextEditingController();

  // ==================================================
  // Cosmetic Gynecology
  // ==================================================

  String? cosmeticInterest;

  final TextEditingController cosmeticQuestionsController =
      TextEditingController();

  final TextEditingController cosmeticGoalController = TextEditingController();

  final TextEditingController previousProcedureController =
      TextEditingController();

  final TextEditingController specialistController = TextEditingController();

  final TextEditingController expectedOutcomeController =
      TextEditingController();

  // ==================================================
  // Selected Answers
  // ==================================================

  String? selectedPainLevel;
  String? selectedMood;

  // ==================================================
  // Dispose Controllers
  // ==================================================

  @override
  void dispose() {
    doctorController.dispose();
    pregnancyNotesController.dispose();
    weeksPregnantController.dispose();
    dueDateController.dispose();
    pregnancySymptomsController.dispose();
    pregnancyConcernsController.dispose();
    firstPregnancyController.dispose();
    antenatalController.dispose();
    complicationsController.dispose();
    vitaminsController.dispose();

    cycleLengthController.dispose();
    lastPeriodController.dispose();
    periodSymptomsController.dispose();
    flowController.dispose();
    periodLengthController.dispose();
    crampsController.dispose();
    regularController.dispose();
    birthControlController.dispose();

    postpartumNotesController.dispose();
    babyAgeController.dispose();
    deliveryTypeController.dispose();
    breastfeedingController.dispose();
    recoveryConcernsController.dispose();
    postpartumWeeksController.dispose();
    sleepController.dispose();
    moodController.dispose();
    postpartumCheckController.dispose();
    postpartumConcernController.dispose();

    healthGoalsController.dispose();
    heightController.dispose();
    weightController.dispose();
    exerciseController.dispose();
    waterController.dispose();
    sleepHoursController.dispose();
    healthConcernController.dispose();

    cosmeticQuestionsController.dispose();
    cosmeticGoalController.dispose();
    previousProcedureController.dispose();
    specialistController.dispose();
    expectedOutcomeController.dispose();

    super.dispose();
  }

  // ==================================================
  // Date Picker
  // ==================================================

  Future<void> pickDate(
    BuildContext context,
    Function(DateTime) onSelected,
  ) async {
    final DateTime initial = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
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
  // Question Text Field
  // ==================================================

  Widget buildQuestion(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF959B7D),
          ),
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
        ),
      ),
    );
  }

  // ==================================================
  // Continue Button
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatbotScreen(
                journey: widget.journey,
              ),
            ),
          );
        },
        child: const Text(
          "Continue to Her Health AI 🌸",
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Background overlay
          Container(
            color: Colors.white.withValues(alpha: 0.25),
          ),

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
                    // Logo
                    // ==================================================

                    Center(
                      child: Image.asset(
                        'assets/images/logo/logo.png',
                        height: 90,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // Journey Name
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
                        "Let's get to know you better so Her Health AI "
                        "can give personalised support.",
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
                      sectionTitle(
                        "🤰 Pregnancy Care",
                      ),
                      buildQuestion(
                        "🤰 How many weeks pregnant are you?",
                        weeksPregnantController,
                      ),
                      buildQuestion(
                        "👩 Is this your first pregnancy?",
                        firstPregnancyController,
                      ),
                      buildQuestion(
                        "🏥 Have you had your first antenatal visit?",
                        antenatalController,
                      ),
                      buildQuestion(
                        "🩸 Do you have any pregnancy complications?",
                        complicationsController,
                      ),
                      buildQuestion(
                        "💊 Are you taking prenatal vitamins?",
                        vitaminsController,
                      ),
                      buildQuestion(
                        "📅 Estimated Due Date",
                        dueDateController,
                      ),
                    ],

                    // ==================================================
                    // MENSTRUAL HEALTH
                    // ==================================================

                    if (widget.journey == "🌸 Menstrual Health") ...[
                      sectionTitle(
                        "🌸 Menstrual Health",
                      ),
                      buildQuestion(
                        "📅 First day of your last period",
                        lastPeriodController,
                      ),
                      buildQuestion(
                        "🔄 Average cycle length (days)",
                        cycleLengthController,
                      ),
                      buildQuestion(
                        "🩸 Average period length (days)",
                        periodLengthController,
                      ),
                      buildQuestion(
                        "😖 Do you experience painful cramps?",
                        crampsController,
                      ),
                      buildQuestion(
                        "😊 Are your periods regular?",
                        regularController,
                      ),
                      buildQuestion(
                        "💊 Are you using any birth control?",
                        birthControlController,
                      ),
                    ],

                    // ==================================================
                    // POSTPARTUM RECOVERY
                    // ==================================================

                    if (widget.journey == "👶 Postpartum Recovery") ...[
                      sectionTitle(
                        "👶 Postpartum Recovery",
                      ),
                      buildQuestion(
                        "🍼 How many weeks postpartum are you?",
                        postpartumWeeksController,
                      ),
                      buildQuestion(
                        "🤱 Are you breastfeeding?",
                        breastfeedingController,
                      ),
                      buildQuestion(
                        "😴 How is your sleep quality?",
                        sleepController,
                      ),
                      buildQuestion(
                        "😊 How has your mood been recently?",
                        moodController,
                      ),
                      buildQuestion(
                        "🩺 Have you attended your postpartum check-up?",
                        postpartumCheckController,
                      ),
                      buildQuestion(
                        "❤️ Do you have any concerns you'd like support with?",
                        postpartumConcernController,
                      ),
                    ],

                    // ==================================================
                    // GENERAL WOMEN'S HEALTH
                    // ==================================================

                    if (widget.journey == "💚 General Women's Health") ...[
                      sectionTitle(
                        "💚 General Women's Health",
                      ),
                      buildQuestion(
                        "📏 Height (cm)",
                        heightController,
                      ),
                      buildQuestion(
                        "⚖️ Weight (kg)",
                        weightController,
                      ),
                      buildQuestion(
                        "🏃 Do you exercise regularly?",
                        exerciseController,
                      ),
                      buildQuestion(
                        "💧 How much water do you drink daily?",
                        waterController,
                      ),
                      buildQuestion(
                        "😴 Average hours of sleep per night",
                        sleepHoursController,
                      ),
                      buildQuestion(
                        "🩺 Any current health concerns?",
                        healthConcernController,
                      ),
                    ],

                    // ==================================================
                    // COSMETIC GYNECOLOGY
                    // ==================================================

                    if (widget.journey == "✨ Cosmetic Gynecology") ...[
                      sectionTitle(
                        "✨ Cosmetic Gynecology",
                      ),
                      buildQuestion(
                        "💬 What would you like to improve?",
                        cosmeticGoalController,
                      ),
                      buildQuestion(
                        "📅 Have you had any previous procedures?",
                        previousProcedureController,
                      ),
                      buildQuestion(
                        "👩‍⚕️ Have you consulted a specialist before?",
                        specialistController,
                      ),
                      buildQuestion(
                        "⭐ What outcome are you hoping for?",
                        expectedOutcomeController,
                      ),
                    ],

                    // ==================================================
                    // CONTINUE
                    // ==================================================

                    const SizedBox(height: 20),

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
