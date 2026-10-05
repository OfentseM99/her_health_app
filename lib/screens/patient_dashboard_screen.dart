import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'period_tracker_screen.dart';
import 'chatbot_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final String? patientName;
  final String? journey;

  const PatientDashboardScreen({
    super.key,
    this.patientName,
    this.journey,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int selectedIndex = 0;

  bool isLoading = true;

  // ============================================================
  // SAVED PATIENT INFORMATION
  // ============================================================

  String savedJourney = "Women's Health";

  String weeksPregnant = "";
  String dueDate = "";

  String lastPeriod = "";
  String cycleLength = "";
  String periodLength = "";

  String postpartumWeeks = "";

  // ============================================================
  // LOAD PATIENT INFORMATION
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadPatientInformation();
  }

  Future<void> _loadPatientInformation() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      savedJourney = prefs.getString('selectedJourney') ??
          widget.journey ??
          "Women's Health";

      weeksPregnant = prefs.getString('weeksPregnant') ?? "";
      dueDate = prefs.getString('dueDate') ?? "";

      lastPeriod = prefs.getString('lastPeriod') ?? "";
      cycleLength = prefs.getString('cycleLength') ?? "";
      periodLength = prefs.getString('periodLength') ?? "";

      postpartumWeeks = prefs.getString('postpartumWeeks') ?? "";

      isLoading = false;
    });
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String get displayName {
    if (widget.patientName != null && widget.patientName!.trim().isNotEmpty) {
      return widget.patientName!;
    }

    return "Name";
  }

  // ============================================================
  // DISPLAY JOURNEY
  // ============================================================

  String get displayJourney {
    if (savedJourney.trim().isNotEmpty) {
      return savedJourney;
    }

    if (widget.journey != null && widget.journey!.trim().isNotEmpty) {
      return widget.journey!;
    }

    return "Women's Health";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF8FA),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE89CB0),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FA),
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  Widget _buildCurrentPage() {
    switch (selectedIndex) {
      case 1:
        return _buildCalendarPage();

      case 2:
        return _buildAIPage();

      case 3:
        return _buildDoctorPage();

      case 4:
        return _buildProfilePage();

      default:
        return _buildHomePage();
    }
  }

  // ============================================================
  // HOME DASHBOARD
  // ============================================================

  Widget _buildHomePage() {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),

                const SizedBox(height: 25),

                Text(
                  "Good morning, $displayName 🌸",
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "How can Her Health help you today?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 22),

                // ====================================================
                // PERSONAL HEALTH JOURNEY
                // ====================================================

                _buildJourneyHealthCard(),

                const SizedBox(height: 20),

                // ====================================================
                // APPOINTMENT
                // ====================================================

                _buildAppointmentCard(),

                const SizedBox(height: 20),

                // ====================================================
                // CYCLE CARD
                // ====================================================

                if (displayJourney == "🌸 Menstrual Health") _buildCycleCard(),

                if (displayJourney == "🌸 Menstrual Health")
                  const SizedBox(height: 25),

                // ====================================================
                // QUICK ACTIONS
                // ====================================================

                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),

                const SizedBox(height: 15),

                _buildQuickActions(),

                const SizedBox(height: 25),

                const Text(
                  "Your Healthcare Journey",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),

                const SizedBox(height: 12),

                _buildJourneyCard(),
              ],
            ),
          ),

          // ============================================================
          // FLOATING AI BUTTON
          // ============================================================

          Positioned(
            right: 18,
            bottom: 20,
            child: _buildFloatingAIButton(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FLOATING AI BUTTON
  // ============================================================

  Widget _buildFloatingAIButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openAI();
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE89CB0),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 7),
              Text(
                "Ask AI",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP HEADER
  // ============================================================

  Widget _buildTopHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo/logo.png',
          height: 55,
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            _showComingSoon("Notifications");
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            size: 29,
            color: Color(0xFF959B7D),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFBECEF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.person_outline,
            color: Color(0xFFE89CB0),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERSONAL JOURNEY HEALTH CARD
  // ============================================================

  Widget _buildJourneyHealthCard() {
    if (displayJourney == "🤰 Pregnancy Care") {
      return _buildPregnancyCard();
    }

    if (displayJourney == "🌸 Menstrual Health") {
      return _buildMenstrualHealthSummary();
    }

    if (displayJourney == "👶 Postpartum Recovery") {
      return _buildPostpartumCard();
    }

    if (displayJourney == "💚 General Women's Health") {
      return _buildGeneralHealthCard();
    }

    if (displayJourney == "✨ Cosmetic Gynecology") {
      return _buildCosmeticCard();
    }

    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "💗 Your Health Journey",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Her Health is here to support you throughout your healthcare journey.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREGNANCY CARD
  // ============================================================

  Widget _buildPregnancyCard() {
    int? currentWeek;
    int? weeksRemaining;
    DateTime? estimatedDueDate;

    final parsedDueDate = _parseDate(dueDate);

    if (parsedDueDate != null) {
      estimatedDueDate = parsedDueDate;

      final today = DateTime.now();

      final difference = estimatedDueDate.difference(today).inDays;

      weeksRemaining = (difference / 7).ceil();

      currentWeek = 40 - weeksRemaining;

      if (currentWeek < 1) {
        currentWeek = 1;
      }

      if (currentWeek > 40) {
        currentWeek = 40;
      }
    } else {
      final enteredWeeks = int.tryParse(weeksPregnant.trim());

      if (enteredWeeks != null) {
        currentWeek = enteredWeeks;
        weeksRemaining = 40 - enteredWeeks;

        if (weeksRemaining < 0) {
          weeksRemaining = 0;
        }
      }
    }

    String weekText;

    if (currentWeek != null) {
      weekText = "You're approximately $currentWeek weeks pregnant 🤰";
    } else {
      weekText = "Your pregnancy journey 🤰";
    }

    String remainingText;

    if (weeksRemaining != null) {
      if (weeksRemaining == 0) {
        remainingText = "Your estimated due date has arrived. 💗";
      } else if (weeksRemaining == 1) {
        remainingText = "About 1 week to go until your estimated due date.";
      } else {
        remainingText =
            "About $weeksRemaining weeks to go until your estimated due date.";
      }
    } else {
      remainingText =
          "Keep your pregnancy information updated so we can support you.";
    }

    String trimester = "";

    if (currentWeek != null) {
      if (currentWeek <= 13) {
        trimester = "First trimester";
      } else if (currentWeek <= 27) {
        trimester = "Second trimester";
      } else {
        trimester = "Third trimester";
      }
    }

    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.pregnant_woman,
                const Color(0xFFE89CB0),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Pregnancy Journey",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            weekText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE89CB0),
            ),
          ),

          if (trimester.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              trimester,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF959B7D),
              ),
            ),
          ],

          const SizedBox(height: 12),

          Text(
            remainingText,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 15),

          if (currentWeek != null) _buildPregnancyProgress(currentWeek),

          if (estimatedDueDate != null) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(
                  Icons.event,
                  color: Color(0xFFE89CB0),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Estimated due date: ${_formatDate(estimatedDueDate)}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // ========================================================
          // SWEET MESSAGE
          // ========================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF5F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "💗",
                  style: TextStyle(fontSize: 25),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Every week is another step closer to meeting your little one. Keep taking care of yourself and remember that you're doing your best. 🌸",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ========================================================
          // AI SYMPTOM SECTION - KEPT HERE
          // ========================================================

          const Text(
            "How are you feeling today?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            "Are you experiencing any pain, discomfort or symptoms you'd like to talk about?",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openAI(
                  message:
                      "I am pregnant and I would like to talk about pain, discomfort or symptoms I am experiencing.",
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                "Talk About Your Symptoms",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREGNANCY PROGRESS
  // ============================================================

  Widget _buildPregnancyProgress(int currentWeek) {
    double progress = currentWeek / 40;

    if (progress > 1) {
      progress = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Pregnancy progress",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            Text(
              "$currentWeek / 40 weeks",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF959B7D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFF5E3E8),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFE89CB0),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MENSTRUAL HEALTH SUMMARY
  // ============================================================

  Widget _buildMenstrualHealthSummary() {
    final periodDate = _parseDate(lastPeriod);

    final parsedCycleLength = int.tryParse(cycleLength.trim()) ?? 28;

    final parsedPeriodLength = int.tryParse(periodLength.trim()) ?? 5;

    if (periodDate == null) {
      return _dashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🌸 Your Cycle",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF959B7D),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Add your last period date so Her Health can calculate your cycle, expected period and fertile window.",
              style: TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final today = DateTime.now();

    final cleanToday = DateTime(today.year, today.month, today.day);

    final cleanPeriod =
        DateTime(periodDate.year, periodDate.month, periodDate.day);

    final difference = cleanToday.difference(cleanPeriod).inDays;

    int cycleDay = (difference % parsedCycleLength) + 1;

    if (cycleDay < 1) {
      cycleDay = 1;
    }

    final nextPeriod = cleanPeriod.add(Duration(days: parsedCycleLength));

    final ovulation = cleanPeriod.add(
      Duration(days: parsedCycleLength - 14),
    );

    final fertileStart = ovulation.subtract(const Duration(days: 5));

    final fertileEnd = ovulation.add(const Duration(days: 1));

    final daysUntilPeriod = nextPeriod.difference(cleanToday).inDays;

    String mainMessage;

    if (cycleDay <= parsedPeriodLength) {
      mainMessage =
          "You're currently around day $cycleDay of your cycle. Be gentle with yourself and remember to listen to your body. 🌸";
    } else if (cleanToday.isAfter(fertileStart) &&
        cleanToday.isBefore(
          fertileEnd.add(const Duration(days: 1)),
        )) {
      mainMessage =
          "You're around your fertile window. Take care of yourself and keep listening to what your body needs. 💚";
    } else {
      mainMessage =
          "You're around day $cycleDay of your cycle. Keep looking after yourself — you've got this! 💕";
    }

    String periodMessage;

    if (daysUntilPeriod == 0) {
      periodMessage = "Your next period is expected today. 🌸";
    } else if (daysUntilPeriod == 1) {
      periodMessage = "Your next period is expected tomorrow. 🌸";
    } else if (daysUntilPeriod > 1) {
      periodMessage = "Your next period is expected in $daysUntilPeriod days.";
    } else {
      periodMessage = "Your next period is around ${_formatDate(nextPeriod)}.";
    }

    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.favorite_outline,
                const Color(0xFFE89CB0),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Your Menstrual Cycle",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Cycle Day $cycleDay",
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE89CB0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mainMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          _cycleDateRow(
            "🌸",
            "Next period",
            _formatDate(nextPeriod),
          ),
          const SizedBox(height: 8),
          _cycleDateRow(
            "🌱",
            "Estimated ovulation",
            _formatDate(ovulation),
          ),
          const SizedBox(height: 8),
          _cycleDateRow(
            "💚",
            "Fertile window",
            "${_formatDate(fertileStart)} - ${_formatDate(fertileEnd)}",
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF5F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              periodMessage,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF959B7D),
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openAI(
                  message:
                      "I am tracking my menstrual cycle and I would like to talk about how I am feeling or any symptoms I am experiencing.",
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                "Talk About Your Symptoms",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CYCLE DATE ROW
  // ============================================================

  Widget _cycleDateRow(
    String emoji,
    String title,
    String date,
  ) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
        Text(
          date,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF959B7D),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // POSTPARTUM CARD
  // ============================================================

  Widget _buildPostpartumCard() {
    final weeks = int.tryParse(postpartumWeeks.trim());

    String weekMessage;

    if (weeks != null) {
      weekMessage = "You are approximately $weeks weeks postpartum. 👶";
    } else {
      weekMessage = "Your postpartum recovery journey 👶";
    }

    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.child_friendly,
                const Color(0xFFE89CB0),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Postpartum Recovery",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            weekMessage,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE89CB0),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Recovery takes time. Give yourself permission to rest, ask for support and look after your physical and emotional wellbeing. 💗",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "How are you feeling today?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Are you experiencing any pain, discomfort or symptoms you'd like to talk about?",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openAI(
                  message:
                      "I am postpartum and I would like to talk about how I am feeling or any recovery concerns I have.",
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                "Talk About Your Symptoms",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENERAL HEALTH CARD
  // ============================================================

  Widget _buildGeneralHealthCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.favorite_outline,
                const Color(0xFFE89CB0),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Your General Health",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Small healthy habits can make a big difference. Keep focusing on your wellbeing one day at a time. 💚",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "How are you feeling today?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            "Is there anything about your health or wellbeing you'd like to talk about?",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openAI(
                  message:
                      "I would like help with my general women's health and wellbeing.",
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                "Talk About Your Health",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COSMETIC CARD
  // ============================================================

  Widget _buildCosmeticCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.auto_awesome,
                const Color(0xFFE89CB0),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Cosmetic Gynecology",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Have questions about cosmetic or specialist procedures? Her Health AI can help you understand your options and prepare questions for a healthcare professional.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Have questions you'd like to ask?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openAI(
                  message:
                      "I have questions about cosmetic gynecology and would like some information.",
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                "Talk About Your Questions",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPEN AI
  // ============================================================

  void _openAI({
    String? message,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotScreen(
          journey: displayJourney,
        ),
      ),
    );
  }

  // ============================================================
  // APPOINTMENT CARD
  // ============================================================

  Widget _buildAppointmentCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.calendar_month_outlined,
                const Color(0xFFE89CB0),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Next Appointment",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _showComingSoon("Appointments");
                },
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: Color(0xFFE89CB0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "No upcoming appointments",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Book an appointment with your healthcare provider.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed: () {
              _showComingSoon("Appointment Booking");
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE89CB0),
              side: const BorderSide(
                color: Color(0xFFE89CB0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text("Book Appointment"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERIOD CARD
  // ============================================================

  Widget _buildCycleCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.favorite_outline,
                const Color(0xFFE89CB0),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Your Cycle",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _cycleInfo(
                  "🌸",
                  "Period",
                  "Track your cycle",
                ),
              ),
              Expanded(
                child: _cycleInfo(
                  "💚",
                  "Ovulation",
                  "Track fertility",
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PeriodTrackerScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
              child: const Text(
                "Open Period Calendar",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cycleInfo(
    String emoji,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 27),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _quickAction(
          Icons.calendar_month_outlined,
          "Appointments",
          () {
            _showComingSoon("Appointments");
          },
        ),
        _quickAction(
          Icons.chat_outlined,
          "Message Doctor",
          () {
            _showComingSoon("Doctor Messaging");
          },
        ),
        _quickAction(
          Icons.notifications_none,
          "Reminders",
          () {
            _showComingSoon("Reminders");
          },
        ),
        _quickAction(
          Icons.credit_card_outlined,
          "Billing",
          () {
            _showComingSoon("Billing");
          },
        ),
      ],
    );
  }

  Widget _quickAction(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFBECEF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE89CB0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF959B7D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // JOURNEY CARD
  // ============================================================

  Widget _buildJourneyCard() {
    return _dashboardCard(
      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFFBECEF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.favorite,
              color: Color(0xFFE89CB0),
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Healthcare Journey",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayJourney,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF959B7D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALENDAR PAGE
  // ============================================================

  Widget _buildCalendarPage() {
    return SafeArea(
      child: Column(
        children: [
          _pageHeader(
            "Health Calendar",
            Icons.calendar_month_outlined,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 80,
                      color: Color(0xFFE89CB0),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Your Health Calendar",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF959B7D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Track your period, fertile window, ovulation and other menstrual cycle information.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PeriodTrackerScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE89CB0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Open Calendar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI PAGE
  // ============================================================

  Widget _buildAIPage() {
    return SafeArea(
      child: Column(
        children: [
          _pageHeader(
            "Her Health AI",
            Icons.smart_toy_outlined,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBECEF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        size: 55,
                        color: Color(0xFFE89CB0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "How can I help you?",
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF959B7D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ask Her Health AI about your healthcare journey, symptoms, cycle or general women's health questions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        _openAI();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE89CB0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Start Chat",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCTOR PAGE
  // ============================================================

  Widget _buildDoctorPage() {
    return SafeArea(
      child: Column(
        children: [
          _pageHeader(
            "My Doctor",
            Icons.medical_services_outlined,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _dashboardCard(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 38,
                        backgroundColor: Color(0xFFFBECEF),
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: Color(0xFFE89CB0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "No doctor assigned yet",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF959B7D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Once a healthcare provider is assigned to your profile, you will be able to communicate with them here.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showComingSoon("Doctor Messaging");
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text("Message Doctor"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE89CB0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _quickAction(
                  Icons.calendar_month_outlined,
                  "Appointments",
                  () {
                    _showComingSoon("Appointments");
                  },
                ),
                const SizedBox(height: 12),
                _quickAction(
                  Icons.description_outlined,
                  "Medical Records",
                  () {
                    _showComingSoon("Medical Records");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE PAGE
  // ============================================================

  Widget _buildProfilePage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          _pageHeader(
            "Health Profile",
            Icons.person_outline,
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              height: 95,
              width: 95,
              decoration: BoxDecoration(
                color: const Color(0xFFFBECEF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.person,
                size: 55,
                color: Color(0xFFE89CB0),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF959B7D),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              displayJourney,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 25),
          _profileOption(
            Icons.person_outline,
            "Personal Information",
          ),
          _profileOption(
            Icons.favorite_outline,
            "Health Information",
          ),
          _profileOption(
            Icons.medication_outlined,
            "Medications",
          ),
          _profileOption(
            Icons.warning_amber_outlined,
            "Allergies",
          ),
          _profileOption(
            Icons.contact_phone_outlined,
            "Emergency Contact",
          ),
          _profileOption(
            Icons.lock_outline,
            "Privacy & Security",
          ),
          _profileOption(
            Icons.settings_outlined,
            "Settings",
          ),
        ],
      ),
    );
  }

  Widget _profileOption(
    IconData icon,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFBECEF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFE89CB0),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF959B7D),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black38,
        ),
        onTap: () {
          _showComingSoon(title);
        },
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFFBECEF),
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home,
            color: Color(0xFFE89CB0),
          ),
          label: "Home",
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(
            Icons.calendar_month,
            color: Color(0xFFE89CB0),
          ),
          label: "Calendar",
        ),
        NavigationDestination(
          icon: Icon(Icons.smart_toy_outlined),
          selectedIcon: Icon(
            Icons.smart_toy,
            color: Color(0xFFE89CB0),
          ),
          label: "AI",
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_outlined),
          selectedIcon: Icon(
            Icons.chat,
            color: Color(0xFFE89CB0),
          ),
          label: "Doctor",
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(
            Icons.person,
            color: Color(0xFFE89CB0),
          ),
          label: "Profile",
        ),
      ],
    );
  }

  // ============================================================
  // REUSABLE DASHBOARD CARD
  // ============================================================

  Widget _dashboardCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox(
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFFBECEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _pageHeader(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFBECEF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE89CB0),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value.trim());

    if (parsed != null) {
      return parsed;
    }

    final parts = value.trim().split(RegExp(r'[/\-.]'));

    if (parts.length == 3) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);

      if (first != null && second != null && third != null) {
        // yyyy-mm-dd
        if (first > 1000) {
          return DateTime(first, second, third);
        }

        // dd-mm-yyyy or dd/mm/yyyy
        if (third > 1000) {
          return DateTime(third, second, first);
        }
      }
    }

    return null;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return "$day/$month/${date.year}";
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$feature will be connected next 🌸",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
