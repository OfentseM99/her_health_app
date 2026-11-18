import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/design_a.dart';
import 'appointments_screen.dart';
import 'articles_screen.dart';
import 'chatbot_screen.dart';
import 'health_history_screen.dart';
import 'health_profile_screen.dart';
import 'health_tracking_screen.dart';
import 'messages_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;

  String _firstName = '';
  Map<String, dynamic>? _journey;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _trackingEntries = [];
  List<Map<String, dynamic>> _bills = [];
  bool _billsLoadFailed = false;
  bool _trackingLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _billsLoadFailed = false;
      _trackingLoadFailed = false;
    });

    try {
      final results = await Future.wait([
        AuthService.getMe(),
        AuthService.getHealthJourney(),
        AuthService.getMyAppointments(),
        AuthService.getReminders(),
      ]);

      if (!mounted) return;

      final profileData = results[0] as Map<String, dynamic>;
      final profile = profileData['profile'];

      final journeyData = results[1];
      final appointmentData = results[2] as List<dynamic>;
      final reminderData = results[3] as List<dynamic>;

      Map<String, dynamic>? activeJourney;

      if (journeyData is Map<String, dynamic>) {
        activeJourney = journeyData;
      } else if (journeyData is Map) {
        activeJourney = Map<String, dynamic>.from(journeyData);
      }

      // Load tracking entries belonging only to the active journey.
      List<dynamic> trackingData = [];

      final rawJourneyId = activeJourney?['id'];
      final journeyId = rawJourneyId is int
          ? rawJourneyId
          : int.tryParse(rawJourneyId?.toString() ?? '');

      if (journeyId != null) {
        try {
          trackingData = await AuthService.getHealthTrackingEntries(
            journeyId: journeyId,
          );
        } catch (_) {
          _trackingLoadFailed = true;
        }
      }

      // Bills are retrieved through the authenticated patient's billing endpoint.
      List<dynamic> billData = [];

      try {
        billData = await AuthService.getMyBills();
      } catch (_) {
        _billsLoadFailed = true;
      }

      if (!mounted) return;

      setState(() {
        _firstName = profile is Map
            ? (profile['first_name']?.toString() ?? '')
            : (AuthService.firstName ?? '');

        _journey = activeJourney;

        _appointments = appointmentData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        _reminders = reminderData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        _trackingEntries = trackingData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        _bills = billData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _journeyType => _journey?['journey_type']?.toString() ?? '';

  String get _journeyName {
    switch (_journeyType) {
      case 'pregnancy_care':
        return 'Pregnancy Care';
      case 'menstrual_health':
        return 'Menstrual Health';
      case 'postpartum_recovery':
        return 'Postpartum Recovery';
      case 'general_health':
        return "General Women's Health";
      case 'cosmetic_gynecology':
        return 'Cosmetic Gynaecology';
      default:
        return 'Your Health Journey';
    }
  }

  String get _journeyDescription {
    switch (_journeyType) {
      case 'pregnancy_care':
        return 'Keep track of your pregnancy, milestones and wellbeing.';
      case 'menstrual_health':
        return 'Understand your cycle and keep a record of your experiences.';
      case 'postpartum_recovery':
        return 'Follow your recovery and wellbeing after delivery.';
      case 'general_health':
        return 'Keep track of your everyday health and wellness.';
      case 'cosmetic_gynecology':
        return 'Keep track of your recovery and aftercare journey.';
      default:
        return 'Your saved health journey and personal tracking space.';
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<Map<String, dynamic>> get _upcomingAppointments {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final items = _appointments.where((appointment) {
      final status = appointment['status']?.toString().toLowerCase();
      final date = _parseDate(appointment['requested_date']);

      return date != null &&
          !date.isBefore(startOfToday) &&
          status != 'cancelled' &&
          status != 'rejected';
    }).toList();

    items.sort((a, b) {
      final dateA = _parseDate(a['requested_date']) ?? DateTime(2100);
      final dateB = _parseDate(b['requested_date']) ?? DateTime(2100);
      return dateA.compareTo(dateB);
    });

    return items.take(3).toList();
  }

  List<Map<String, dynamic>> get _pendingReminders {
    final items = _reminders.where((reminder) {
      return reminder['is_done'] != true;
    }).toList();

    items.sort((a, b) {
      final dateA = _parseDate(a['remind_at']) ?? DateTime(2100);
      final dateB = _parseDate(b['remind_at']) ?? DateTime(2100);
      return dateA.compareTo(dateB);
    });

    return items.take(3).toList();
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: DA.heading(20)),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all',
                style: DA.body(13, color: DA.rose, weight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _journeyCard() {
    final createdAt = _parseDate(_journey?['created_at']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DA.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DA.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: DA.blush,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.favorite_outline_rounded,
                  color: DA.rose,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR ACTIVE JOURNEY',
                      style: DA
                          .body(
                            11,
                            color: DA.quiet,
                            weight: FontWeight.w700,
                          )
                          .copyWith(letterSpacing: 1),
                    ),
                    const SizedBox(height: 3),
                    Text(_journeyName, style: DA.heading(19)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: DA.sage, size: 21),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _journeyDescription,
            style: DA.body(14, color: DA.muted),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Started ${_formatDate(createdAt)}',
              style: DA.body(12, color: DA.quiet),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openScreen(const HealthTrackingScreen()),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('Open Health Tracking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DA.rose,
                side: const BorderSide(color: DA.rose),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> get _journeyAnswers {
    final answers = _journey?['answers'];
    if (answers is Map<String, dynamic>) return answers;
    if (answers is Map) return Map<String, dynamic>.from(answers);
    return {};
  }

  int? get _pregnancyWeekForDashboard {
    if (_journeyType != 'pregnancy_care') return null;

    final dueDate = _parseDate(_journeyAnswers['due_date']);

    if (dueDate != null) {
      final today = DateTime.now();
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final current = DateTime(today.year, today.month, today.day);
      final elapsedDays = 280 - due.difference(current).inDays;

      if (elapsedDays < 0 || elapsedDays > 294) return null;
      return elapsedDays ~/ 7;
    }

    final rawWeeks = _journeyAnswers['weeks_pregnant']?.toString() ?? '';
    final match = RegExp(r'\d+').firstMatch(rawWeeks);
    if (match == null) return null;

    final weeks = int.tryParse(match.group(0)!);
    if (weeks == null || weeks < 0 || weeks > 42) return null;

    final createdAt = _parseDate(_journey?['created_at']);
    if (createdAt == null) return weeks;

    final elapsed = DateTime.now().difference(createdAt).inDays;
    return ((weeks * 7 + elapsed) ~/ 7).clamp(0, 42);
  }

  DateTime? get _latestTrackingDate {
    final dates = _trackingEntries
        .map((entry) => _parseDate(entry['entry_date']))
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return null;

    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  Widget _dashboardActivityCard() {
    final week = _pregnancyWeekForDashboard;
    final latestDate = _latestTrackingDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DA.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DA.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: DA.sage, size: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your journey progress',
                  style: DA.heading(18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_journeyType == 'pregnancy_care' && week != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Week $week',
                  style: DA.heading(25),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'of 40 weeks',
                    style: DA.body(13, color: DA.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (week / 40).clamp(0.0, 1.0),
                minHeight: 9,
                backgroundColor: DA.blush,
                valueColor: const AlwaysStoppedAnimation<Color>(DA.sage),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${((week / 40) * 100).round()}% of the 40-week pregnancy timeline',
              style: DA.body(12, color: DA.muted),
            ),
          ] else if (_journeyType == 'pregnancy_care') ...[
            Text(
              'Pregnancy progress is not available yet.',
              style: DA.body(13, color: DA.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Update your saved pregnancy dates or details in Health Tracking.',
              style: DA.body(12, color: DA.quiet),
            ),
          ],
          const SizedBox(height: 14),
          Divider(color: DA.border),
          if (_trackingLoadFailed)
            Text(
              'Tracking activity could not be loaded. Please refresh to try again.',
              style: DA.body(12, color: DA.muted),
            )
          else ...[
            Text(
              '${_trackingEntries.length} recorded ${_trackingEntries.length == 1 ? 'entry' : 'entries'} in this active journey',
              style: DA.body(14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              latestDate == null
                  ? 'No tracking entries have been recorded yet.'
                  : 'Most recent entry: ${_formatDate(latestDate)}',
              style: DA.body(12, color: DA.muted),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openScreen(const HealthTrackingScreen()),
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('View health tracking'),
              style: TextButton.styleFrom(foregroundColor: DA.rose),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBillAmount(dynamic value) {
    final amount = num.tryParse(value?.toString() ?? '');
    if (amount == null) return 'Amount unavailable';
    return 'R${amount.toStringAsFixed(2)}';
  }

  Widget _billSection() {
    final items = _bills.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Your bills'),
        if (_billsLoadFailed)
          _emptyCard(
            icon: Icons.receipt_long_outlined,
            message:
                'Your billing information could not be loaded. Please refresh.',
          )
        else if (items.isEmpty)
          _emptyCard(
            icon: Icons.receipt_long_outlined,
            message: 'You do not have any bills recorded at the moment.',
          )
        else
          ...items.map((bill) {
            final description = bill['description']?.toString().trim() ?? '';
            final status =
                bill['status']?.toString().toLowerCase() ?? 'unknown';
            final dueDate = _parseDate(bill['due_date']);

            final statusLabel = status == 'partially_paid'
                ? 'Partially paid'
                : status == 'paid'
                    ? 'Paid'
                    : status == 'unpaid'
                        ? 'Unpaid'
                        : 'Status unavailable';

            final statusColor = status == 'paid'
                ? DA.sage
                : status == 'unpaid'
                    ? DA.rose
                    : DA.muted;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: DA.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DA.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DA.blush,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: DA.rose,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description.isEmpty ? 'Bill' : description,
                          style: DA.body(14, weight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dueDate == null
                              ? 'Due date unavailable'
                              : 'Due ${_formatDate(dueDate)}',
                          style: DA.body(12, color: DA.muted),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          statusLabel,
                          style: DA.body(
                            12,
                            color: statusColor,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatBillAmount(bill['amount']),
                    style: DA.body(13, weight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openScreen(screen),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: DA.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DA.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DA.sage, size: 25),
            const SizedBox(height: 13),
            Text(title, style: DA.body(14, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: DA.body(11, color: DA.quiet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentSection() {
    final items = _upcomingAppointments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Upcoming appointments',
          onSeeAll: () => _openScreen(const AppointmentsScreen()),
        ),
        if (items.isEmpty)
          _emptyCard(
            icon: Icons.calendar_month_outlined,
            message: 'No upcoming appointments at the moment.',
          )
        else
          ...items.map((appointment) {
            final date = _parseDate(appointment['requested_date']);
            final time = appointment['requested_time']?.toString() ?? '';
            final reason = appointment['reason']?.toString() ?? '';
            final status = appointment['status']?.toString() ?? 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: DA.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DA.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: DA.sage,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reason.isEmpty ? 'Appointment' : reason,
                          style: DA.body(14, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date == null ? 'Date unavailable' : _formatDate(date)}${time.isEmpty ? '' : ' Â· $time'}',
                          style: DA.body(12, color: DA.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.isEmpty
                        ? 'Pending'
                        : '${status[0].toUpperCase()}${status.substring(1)}',
                    style: DA.body(11, color: DA.rose, weight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _reminderSection() {
    final items = _pendingReminders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Your reminders',
          onSeeAll: () => _openScreen(const RemindersScreen()),
        ),
        if (items.isEmpty)
          _emptyCard(
            icon: Icons.notifications_none_rounded,
            message: 'You have no outstanding reminders.',
          )
        else
          ...items.map((reminder) {
            final date = _parseDate(reminder['remind_at']);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: DA.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DA.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: DA.sage,
                    size: 23,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder['title']?.toString() ?? 'Reminder',
                          style: DA.body(14, weight: FontWeight.w700),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(date),
                            style: DA.body(12, color: DA.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DA.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DA.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: DA.quiet, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: DA.body(13, color: DA.muted)),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          _firstName.trim().isEmpty
              ? 'Welcome back'
              : 'Welcome back, $_firstName',
          style: DA.heading(27),
        ),
        const SizedBox(height: 5),
        Text(
          'Your health and wellbeing, all in one place.',
          style: DA.body(14, color: DA.muted),
        ),
        const SizedBox(height: 22),
        if (_journey != null) ...[
          _journeyCard(),
          const SizedBox(height: 16),
          _dashboardActivityCard(),
        ] else
          _emptyCard(
            icon: Icons.favorite_outline_rounded,
            message:
                'You do not have an active health journey yet. Open Health Tracking to get started.',
          ),
        const SizedBox(height: 25),
        _appointmentSection(),
        const SizedBox(height: 20),
        _reminderSection(),
        const SizedBox(height: 20),
        _billSection(),
        const SizedBox(height: 25),
        _sectionTitle('Quick access'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _quickAction(
              icon: Icons.monitor_heart_outlined,
              title: 'Health Tracking',
              subtitle: 'Your health records',
              screen: const HealthTrackingScreen(),
            ),
            _quickAction(
              icon: Icons.person_outline_rounded,
              title: 'Health Profile',
              subtitle: 'Your profile details',
              screen: const HealthProfileScreen(),
            ),
            _quickAction(
              icon: Icons.calendar_month_outlined,
              title: 'Appointments',
              subtitle: 'View and request visits',
              screen: const AppointmentsScreen(),
            ),
            _quickAction(
              icon: Icons.auto_awesome_outlined,
              title: 'Ask Nia',
              subtitle: 'Your health assistant',
              screen: const ChatbotScreen(),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: DA.blush.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_outline, color: DA.rose, size: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your wellbeing matters. Take things one step at a time.',
                  style: DA.body(13, color: DA.ink, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: DA.ground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
          children: [
            Text('Her Health', style: DA.heading(25)),
            const SizedBox(height: 5),
            Text(
              _firstName.trim().isEmpty
                  ? 'Your wellness space'
                  : 'Hi, $_firstName',
              style: DA.body(14, color: DA.muted),
            ),
            const SizedBox(height: 20),
            _drawerItem(Icons.dashboard_outlined, 'Dashboard', null),
            _drawerItem(Icons.auto_awesome_outlined, 'AI Assistant',
                const ChatbotScreen()),
            _drawerItem(Icons.calendar_month_outlined, 'Appointments',
                const AppointmentsScreen()),
            _drawerItem(Icons.medical_services_outlined, 'Contact Doctor',
                const MessagesScreen()),
            _drawerItem(Icons.favorite_border_rounded, 'Health Profile',
                const HealthProfileScreen()),
            _drawerItem(Icons.monitor_heart_outlined, 'Health Tracking',
                const HealthTrackingScreen()),
            _drawerItem(Icons.history_rounded, 'Health History',
                const HealthHistoryScreen()),
            _drawerItem(Icons.notifications_none_rounded, 'Reminders',
                const RemindersScreen()),
            _drawerItem(Icons.article_outlined, 'Health Articles',
                const ArticlesScreen()),
            _drawerItem(
                Icons.settings_outlined, 'Settings', const SettingsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Widget? screen) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Icon(icon, color: DA.sage),
      title: Text(title, style: DA.body(14, weight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        if (screen == null) {
          Navigator.pop(context);
          if (title == 'Dashboard') {
            _loadDashboard();
          }
        } else {
          Navigator.pop(context);
          _openScreen(screen);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: DA.ground,
        foregroundColor: DA.ink,
        elevation: 0,
        title: Text('Her Health', style: DA.heading(20)),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DA.rose),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          color: DA.quiet,
                          size: 40,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'We could not load your dashboard.',
                          style: DA.heading(18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your connection and try again.',
                          style: DA.body(14, color: DA.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboard,
                          style: DA.primary(),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: DA.rose,
                  onRefresh: _loadDashboard,
                  child: _buildDashboard(),
                ),
    );
  }
}
