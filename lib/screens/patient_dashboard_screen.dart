import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'billing_screen.dart';
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
  // Her Health colours
  static const Color rose = Color(0xFFB04F6C);
  static const Color lightRose = Color(0xFFD9879E);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);
  static const Color pageBackground = Color(0xFFFAF6F3);

  int selectedIndex = 0;
  bool isLoading = true;

  String savedJourney = "Women's Health";
  String weeksPregnant = '';
  String dueDate = '';
  String lastPeriod = '';
  String cycleLength = '';
  String periodLength = '';
  String postpartumWeeks = '';
  String profileName = '';
  String? profileImagePath;

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

      weeksPregnant = prefs.getString('weeksPregnant') ?? '';
      dueDate = prefs.getString('dueDate') ?? '';
      lastPeriod = prefs.getString('lastPeriod') ?? '';
      cycleLength = prefs.getString('cycleLength') ?? '';
      periodLength = prefs.getString('periodLength') ?? '';
      postpartumWeeks = prefs.getString('postpartumWeeks') ?? '';
      profileName = prefs.getString('profile_full_name') ?? '';
      profileImagePath = prefs.getString('profile_image_path');

      isLoading = false;
    });
  }

  String get displayName {
    final savedName = profileName.trim();
    if (savedName.isNotEmpty) return savedName;

    final name = widget.patientName?.trim();
    if (name != null && name.isNotEmpty) return name;

    return 'there';
  }

  String get displayJourney {
    final journey = savedJourney.trim();

    if (journey.isNotEmpty) {
      return journey;
    }

    return widget.journey ?? "Women's Health";
  }

  // Accepts the journey names with or without leading emojis.
  String get journeyKey {
    final journey = displayJourney.toLowerCase();

    if (journey.contains('pregnancy')) return 'pregnancy';
    if (journey.contains('menstrual')) return 'menstrual';
    if (journey.contains('postpartum')) return 'postpartum';
    if (journey.contains('cosmetic')) return 'cosmetic';

    if (journey.contains('general') ||
        journey.contains("women's health") ||
        journey.contains('womens health')) {
      return 'general';
    }

    return 'general';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: CircularProgressIndicator(color: rose),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

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

  // HOME DASHBOARD

  Widget _buildHomePage() {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/background.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: pageBackground),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: pageBackground.withValues(alpha: 0.68),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 28),
                Text(
                  'Good day, $displayName',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your health matters. Let's take it one day at a time.",
                  style: TextStyle(
                    fontSize: 15,
                    color: warmText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildJourneyHealthCard(),
                const SizedBox(height: 18),
                _buildAppointmentCard(),
                if (journeyKey == 'menstrual') ...[
                  const SizedBox(height: 18),
                  _buildCycleCard(),
                ],
                const SizedBox(height: 25),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 14),
                _buildQuickActions(),
                const SizedBox(height: 25),
                const Text(
                  'Your Healthcare Journey',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
                const SizedBox(height: 14),
                _buildJourneyCard(),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: _buildFloatingAIButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo/logo.png',
          height: 52,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.favorite,
            color: rose,
            size: 38,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _showComingSoon('Notifications'),
          icon: const Icon(
            Icons.notifications_none_rounded,
            size: 28,
            color: rose,
          ),
        ),
        InkWell(
          onTap: _showProfilePhoto,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: blush,
              borderRadius: BorderRadius.circular(17),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: profileImagePath != null &&
                      profileImagePath!.isNotEmpty
                  ? Image.file(
                      File(profileImagePath!),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_outline,
                        color: rose,
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: rose,
                      size: 30,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showProfilePhoto() async {
    final imagePath = profileImagePath;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;

        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imagePath != null && imagePath.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: screenSize.height * 0.60,
                      maxWidth: screenSize.width * 0.85,
                    ),
                    child: InteractiveViewer(
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          size: 100,
                          color: rose,
                        ),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.person_outline,
                    size: 100,
                    color: rose,
                  ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await Navigator.pushNamed(context, '/profile');
                        if (!mounted) return;
                        await _loadPatientInformation();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // PERSONAL HEALTH JOURNEY

  Widget _buildJourneyHealthCard() {
    switch (journeyKey) {
      case 'pregnancy':
        return _buildPregnancyCard();
      case 'menstrual':
        return _buildMenstrualHealthCard();
      case 'postpartum':
        return _buildPostpartumCard();
      case 'cosmetic':
        return _buildCosmeticCard();
      default:
        return _buildGeneralHealthCard();
    }
  }

  Widget _buildPregnancyCard() {
    int? currentWeek;
    int? weeksRemaining;
    DateTime? estimatedDueDate;

    final parsedDueDate = _parseDate(dueDate);

    if (parsedDueDate != null) {
      estimatedDueDate = parsedDueDate;

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final due = DateTime(
        parsedDueDate.year,
        parsedDueDate.month,
        parsedDueDate.day,
      );

      weeksRemaining = (due.difference(todayDate).inDays / 7).ceil();
      currentWeek = (40 - weeksRemaining).clamp(1, 40);
      weeksRemaining = weeksRemaining.clamp(0, 40);
    } else {
      final enteredWeeks = int.tryParse(weeksPregnant.trim());

      if (enteredWeeks != null && enteredWeeks >= 1 && enteredWeeks <= 42) {
        currentWeek = enteredWeeks;
        weeksRemaining = (40 - enteredWeeks).clamp(0, 40);
      }
    }

    String trimester = '';

    if (currentWeek != null) {
      if (currentWeek <= 13) {
        trimester = 'First trimester';
      } else if (currentWeek <= 27) {
        trimester = 'Second trimester';
      } else {
        trimester = 'Third trimester';
      }
    }

    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading(
            Icons.favorite_border,
            'Pregnancy Journey',
          ),
          const SizedBox(height: 20),
          Text(
            currentWeek == null
                ? 'Your pregnancy journey'
                : 'Week $currentWeek of your pregnancy',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: rose,
            ),
          ),
          if (trimester.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              trimester,
              style: const TextStyle(
                color: forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            weeksRemaining == null
                ? 'Add your pregnancy information to see your estimated progress.'
                : weeksRemaining == 0
                    ? 'Your estimated due date has arrived.'
                    : 'Approximately $weeksRemaining weeks until your estimated due date.',
            style: const TextStyle(
              color: warmText,
              height: 1.5,
            ),
          ),
          if (currentWeek != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pregnancy progress',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: warmText,
                    ),
                  ),
                ),
                Text(
                  '$currentWeek / 40 weeks',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: currentWeek / 40,
                minHeight: 9,
                backgroundColor: blush,
                valueColor: const AlwaysStoppedAnimation<Color>(rose),
              ),
            ),
          ],
          if (estimatedDueDate != null) ...[
            const SizedBox(height: 18),
            _informationRow(
              Icons.event_outlined,
              'Estimated due date',
              _formatDate(estimatedDueDate),
            ),
          ],
          const SizedBox(height: 20),
          _softMessage(
            Icons.favorite_border,
            'Take things one day at a time. Looking after yourself is an important part of your journey.',
          ),
          const SizedBox(height: 18),
          _symptomButton(
            'Talk About Your Symptoms',
            'I am pregnant and would like to discuss symptoms or questions about my pregnancy.',
          ),
        ],
      ),
    );
  }

  Widget _buildMenstrualHealthCard() {
    final periodDate = _parseDate(lastPeriod);
    final parsedCycleLength = int.tryParse(cycleLength.trim()) ?? 28;
    final parsedPeriodLength = int.tryParse(periodLength.trim()) ?? 5;

    if (periodDate == null ||
        parsedCycleLength < 1 ||
        parsedPeriodLength < 1 ||
        parsedPeriodLength > parsedCycleLength) {
      return _dashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeading(
              Icons.calendar_month_outlined,
              'Your Menstrual Health',
            ),
            const SizedBox(height: 15),
            const Text(
              'Your cycle information will appear here once your last period date and cycle details are available.',
              style: TextStyle(
                color: warmText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            _outlinedAction(
              'Open Period Tracker',
              () => _openPeriodTracker(),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      periodDate.year,
      periodDate.month,
      periodDate.day,
    );

    final daysSincePeriod = today.difference(start).inDays;
    final cycleDay = (daysSincePeriod % parsedCycleLength) + 1;

    final nextPeriod = start.add(
      Duration(
        days: ((daysSincePeriod ~/ parsedCycleLength) + 1) * parsedCycleLength,
      ),
    );

    final ovulation = nextPeriod.subtract(const Duration(days: 14));
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    final daysUntilPeriod = nextPeriod.difference(today).inDays;

    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading(
            Icons.calendar_month_outlined,
            'Your Menstrual Cycle',
          ),
          const SizedBox(height: 20),
          Text(
            'Cycle Day $cycleDay',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: rose,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cycleDay <= parsedPeriodLength
                ? 'You may be on your period. Listen to your body and give yourself the care you need.'
                : 'Keep checking in with your body and tracking how you feel throughout your cycle.',
            style: const TextStyle(
              color: warmText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _informationRow(
            Icons.event_outlined,
            'Expected next period',
            _formatDate(nextPeriod),
          ),
          const SizedBox(height: 12),
          _informationRow(
            Icons.spa_outlined,
            'Estimated ovulation',
            _formatDate(ovulation),
          ),
          const SizedBox(height: 12),
          _informationRow(
            Icons.date_range_outlined,
            'Estimated fertile window',
            '${_formatDate(fertileStart)} â€“ ${_formatDate(fertileEnd)}',
          ),
          const SizedBox(height: 18),
          _softMessage(
            Icons.info_outline,
            'These dates are estimates based on your cycle information. They are not a guarantee of ovulation or a reliable method of preventing pregnancy.',
          ),
          const SizedBox(height: 18),
          _outlinedAction(
            'Open Period Tracker',
            () => _openPeriodTracker(),
          ),
          const SizedBox(height: 12),
          _symptomButton(
            'Talk About Your Symptoms',
            'I am tracking my menstrual cycle and would like to discuss my symptoms.',
          ),
        ],
      ),
    );
  }

  Widget _buildPostpartumCard() {
    final weeks = int.tryParse(postpartumWeeks.trim());

    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading(
            Icons.child_friendly_outlined,
            'Postpartum Recovery',
          ),
          const SizedBox(height: 20),
          Text(
            weeks != null && weeks >= 0
                ? 'Around $weeks weeks postpartum'
                : 'Your recovery journey',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: rose,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Recovery is personal and can take time. Rest when possible, ask for support and look after your physical and emotional wellbeing.',
            style: TextStyle(
              color: warmText,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          _softMessage(
            Icons.favorite_border,
            'You deserve care and support while you care for your little one.',
          ),
          const SizedBox(height: 18),
          _symptomButton(
            'Talk About Your Recovery',
            'I am postpartum and would like to discuss my recovery or symptoms.',
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralHealthCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading(
            Icons.favorite_border,
            'Your General Health',
          ),
          const SizedBox(height: 18),
          const Text(
            'Your wellbeing matters. Use this space to explore health questions, understand your body and build healthy habits at your own pace.',
            style: TextStyle(
              color: warmText,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          _softMessage(
            Icons.spa_outlined,
            'Small steps towards your wellbeing are worth celebrating.',
          ),
          const SizedBox(height: 18),
          _symptomButton(
            'Talk About Your Health',
            'I would like help with my general womenâ€™s health and wellbeing.',
          ),
        ],
      ),
    );
  }

  Widget _buildCosmeticCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading(
            Icons.spa_outlined,
            'Cosmetic Gynecology',
          ),
          const SizedBox(height: 18),
          const Text(
            'Explore information about cosmetic gynecology and specialist procedures. A qualified healthcare professional can explain potential benefits, risks and suitable options.',
            style: TextStyle(
              color: warmText,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          _softMessage(
            Icons.info_outline,
            'Make informed decisions with guidance from a qualified healthcare professional.',
          ),
          const SizedBox(height: 18),
          _symptomButton(
            'Ask a Health Question',
            'I have questions about cosmetic gynecology and would like general information.',
          ),
        ],
      ),
    );
  }

  // APPOINTMENTS

  Widget _buildAppointmentCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.calendar_month_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Next Appointment',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showComingSoon('Appointments'),
                child: const Text(
                  'View All',
                  style: TextStyle(color: rose),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'No upcoming appointments',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: warmText,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your appointment information will be available here.',
            style: TextStyle(
              color: warmText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _outlinedAction(
            'Book Appointment',
            () => _showComingSoon('Appointment Booking'),
          ),
        ],
      ),
    );
  }

  // QUICK ACTIONS

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _quickAction(
          Icons.calendar_month_outlined,
          'Appointments',
          () => _showComingSoon('Appointments'),
        ),
        _quickAction(
          Icons.chat_outlined,
          'Message Doctor',
          () => _showComingSoon('Doctor Messaging'),
        ),
        _quickAction(
          Icons.notifications_none_rounded,
          'Reminders',
          () => _showComingSoon('Reminders'),
        ),
        _quickAction(
          Icons.receipt_long_outlined,
          'Billing',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BillingScreen(),
              ),
            );
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBox(icon),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: forestGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCycleCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeading(
            Icons.calendar_month_outlined,
            'Cycle Tracker',
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep your period dates and cycle information together in one place.',
            style: TextStyle(
              color: warmText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _outlinedAction(
            'Open Period Calendar',
            _openPeriodTracker,
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard() {
    return _dashboardCard(
      child: Row(
        children: [
          _iconBox(Icons.favorite_border, size: 52),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Current Journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: warmText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayJourney,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAIButton() {
    return Material(
      color: rose,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      child: InkWell(
        onTap: _openAI,
        borderRadius: BorderRadius.circular(30),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 13,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Ask AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CALENDAR PAGE

  Widget _buildCalendarPage() {
    return SafeArea(
      child: Column(
        children: [
          _pageHeader(
            'Health Calendar',
            Icons.calendar_month_outlined,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: _dashboardCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBox(
                        Icons.calendar_month_outlined,
                        size: 76,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Health Calendar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Keep track of your period, cycle information and other health notes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: warmText,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _primaryAction(
                        'Open Period Tracker',
                        _openPeriodTracker,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AI PAGE

  Widget _buildAIPage() {
    return SafeArea(
      child: Column(
        children: [
          _pageHeader(
            'Her Health AI',
            Icons.chat_bubble_outline,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: _dashboardCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBox(
                        Icons.smart_toy_outlined,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'How can I help you?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ask questions about your healthcare journey, symptoms or general womenâ€™s health.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: warmText,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _primaryAction('Start Chat', _openAI),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DOCTOR PAGE

  Widget _buildDoctorPage() {
    return SafeArea(
      child: Column(
        children: [
          _pageHeader(
            'My Doctor',
            Icons.medical_services_outlined,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _dashboardCard(
                  child: Column(
                    children: [
                      _iconBox(
                        Icons.person_outline,
                        size: 75,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'No doctor assigned yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: forestGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your doctor details and messaging options can be shown here when that feature is connected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: warmText,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _primaryAction(
                        'Message Doctor',
                        () => _showComingSoon('Doctor Messaging'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _quickAction(
                  Icons.calendar_month_outlined,
                  'Appointments',
                  () => _showComingSoon('Appointments'),
                ),
                const SizedBox(height: 12),
                _quickAction(
                  Icons.description_outlined,
                  'Medical Records',
                  () => _showComingSoon('Medical Records'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PROFILE PAGE

  Widget _buildProfilePage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          _pageHeader(
            'Health Profile',
            Icons.person_outline,
          ),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: blush,
              backgroundImage: profileImagePath != null &&
                      profileImagePath!.isNotEmpty
                  ? FileImage(File(profileImagePath!))
                  : null,
              child: profileImagePath == null ||
                      profileImagePath!.isEmpty
                  ? const Icon(
                      Icons.person_outline,
                      size: 45,
                      color: rose,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              displayJourney,
              textAlign: TextAlign.center,
              style: const TextStyle(color: warmText),
            ),
          ),
          const SizedBox(height: 25),
          _profileOption(
            Icons.person_outline,
            'Personal Information',
          ),
          _profileOption(
            Icons.favorite_border,
            'Health Information',
          ),
          _profileOption(
            Icons.medication_outlined,
            'Medications',
          ),
          _profileOption(
            Icons.warning_amber_outlined,
            'Allergies',
          ),
          _profileOption(
            Icons.contact_phone_outlined,
            'Emergency Contact',
          ),
          _profileOption(
            Icons.lock_outline,
            'Privacy & Security',
          ),
          _profileOption(
            Icons.settings_outlined,
            'Settings',
          ),
        ],
      ),
    );
  }

  Widget _profileOption(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: ListTile(
        leading: _iconBox(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: forestGreen,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: warmText,
        ),
        onTap: () async {
          if (title == 'Personal Information') {
            await Navigator.pushNamed(context, '/profile');
            await _loadPatientInformation();
          } else if (title == 'Settings') {
            await Navigator.pushNamed(context, '/settings');
          } else {
            _showComingSoon(title);
          }
        },
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: Colors.white,
      indicatorColor: blush,
      onDestinationSelected: (index) {
        if (index == 5) {
          Navigator.pushNamed(context, '/user-qr');
          return;
        }

        setState(() {
          selectedIndex = index;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: rose),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month, color: rose),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.smart_toy_outlined),
          selectedIcon: Icon(Icons.smart_toy, color: rose),
          label: 'AI',
        ),
        NavigationDestination(
          icon: Icon(Icons.medical_services_outlined),
          selectedIcon: Icon(Icons.medical_services, color: rose),
          label: 'Doctor',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: rose),
          label: 'Profile',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_2_outlined),
          selectedIcon: Icon(Icons.qr_code_2, color: rose),
          label: 'My QR',
        ),
      ],
    );
  }

  // REUSABLE DESIGN COMPONENTS

  Widget _dashboardCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: forestGreen.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeading(IconData icon, String title) {
    return Row(
      children: [
        _iconBox(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: forestGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBox(
    IconData icon, {
    double size = 45,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: blush,
        borderRadius: BorderRadius.circular(size > 50 ? 25 : 14),
      ),
      child: Icon(
        icon,
        color: rose,
        size: size > 50 ? 36 : 23,
      ),
    );
  }

  Widget _softMessage(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3F3),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: rose, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: warmText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: rose, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: warmText),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: forestGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryAction(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: rose,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _outlinedAction(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: rose,
          side: const BorderSide(color: rose),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _symptomButton(String label, String message) {
    return _primaryAction(
      label,
      () => _openAI(message: message),
    );
  }

  Widget _pageHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NAVIGATION AND HELPERS

  void _openAI({String? message}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(journey: displayJourney),
      ),
    );
  }

  void _openPeriodTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PeriodTrackerScreen(),
      ),
    );
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;

    final parsed = DateTime.tryParse(value.trim());

    if (parsed != null) return parsed;

    final parts = value.trim().split(RegExp(r'[/\-.]'));

    if (parts.length == 3) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);

      if (first != null && second != null && third != null) {
        if (first > 1000) {
          return _validDate(first, second, third);
        }

        if (third > 1000) {
          return _validDate(third, second, first);
        }
      }
    }

    return null;
  }

  DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final date = DateTime(year, month, day);

    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be connected next.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}