import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/passkey_service.dart';
import '../theme/design_a.dart';
import 'articles_manage_screen.dart';
import 'billing_screen.dart';
import 'login_screen.dart';
import 'messages_inbox_screen.dart';
import 'patients_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _deviceUnlockBusy = false;
  bool _sidebarVisible = true;

  String? _errorMessage;

  List<dynamic> _patients = [];
  List<dynamic> _appointments = [];
  List<dynamic> _threads = [];
  List<dynamic> _bills = [];
  List<dynamic> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<dynamic> _request(String path) async {
    try {
      return await ApiService.authorizedGet(path);
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _decodeList(dynamic response) {
    if (response == null || response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException('Expected a list response.');
    }

    return decoded;
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        _request('/patients/all'),
        _request('/appointments/all'),
        _request('/messages/threads'),
        _request('/billing/all'),
        _request('/articles'),
      ]);

      if (!mounted) return;

      if (responses.any(
        (response) =>
            response != null &&
            (response.statusCode == 401 || response.statusCode == 403),
      )) {
        await _handleSessionExpired();
        return;
      }

      final failures = <String>[];
      const labels = [
        'patients',
        'appointments',
        'messages',
        'billing',
        'articles',
      ];

      final decoded = <List<dynamic>>[];

      for (var i = 0; i < responses.length; i++) {
        final response = responses[i];

        if (response == null || response.statusCode != 200) {
          failures.add(labels[i]);
          decoded.add([]);
          continue;
        }

        try {
          decoded.add(_decodeList(response));
        } catch (_) {
          failures.add(labels[i]);
          decoded.add([]);
        }
      }

      setState(() {
        _patients = decoded[0];
        _appointments = decoded[1];
        _threads = decoded[2];
        _bills = decoded[3];
        _articles = decoded[4];

        _errorMessage = failures.isEmpty
            ? null
            : 'Some information could not be loaded: ${failures.join(', ')}. Pull down to refresh.';

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Could not load dashboard information. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _enableDeviceUnlock() async {
    if (_deviceUnlockBusy) return;

    setState(() {
      _deviceUnlockBusy = true;
    });

    try {
      if (!kIsWeb) {
        final enabled = await ApiService.enableBiometricUnlock();

        if (!mounted) return;

        _showMessage(
          enabled
              ? 'Fingerprint or face unlock enabled successfully.'
              : 'No enrolled biometrics were found, or setup was cancelled.',
          error: !enabled,
        );
        return;
      }

      final available = await PasskeyService.isAvailable();

      if (!available) {
        if (!mounted) return;

        _showMessage(
          'Device unlock is not available on this device or browser.',
          error: true,
        );
        return;
      }

      final options = await ApiService.beginPasskeyRegistration();
      final credentialJson = await PasskeyService.register(jsonEncode(options));
      final decoded = jsonDecode(credentialJson);

      if (decoded is! Map) {
        throw Exception('The device returned an invalid credential.');
      }

      await ApiService.finishPasskeyRegistration(
        credential: Map<String, dynamic>.from(decoded),
        deviceName: 'Admin device',
      );

      if (!mounted) return;

      _showMessage('Device unlock enabled successfully.');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().toLowerCase();

      if (message.contains('notallowed') || message.contains('cancel')) {
        _showMessage('Device unlock setup was cancelled.', error: true);
      } else {
        _showMessage('Could not enable device unlock.', error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _deviceUnlockBusy = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade400 : null,
      ),
    );
  }

  Future<void> _handleSessionExpired() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _updateStatus(int appointmentId, String status) async {
    try {
      final response = await ApiService.authorizedPut(
        '/appointments/$appointmentId/status',
        {'status': status},
      );

      if (!mounted) return;

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleSessionExpired();
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showMessage(
          status == 'approved'
              ? 'Appointment approved.'
              : 'Appointment rejected.',
        );
        await _loadDashboard();
      } else {
        _showMessage(
          'Failed to update appointment (${response.statusCode}).',
          error: true,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Could not reach the server. The appointment was not updated.',
        error: true,
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _openPatients() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientsScreen()),
    );
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MessagesInboxScreen()),
    );
  }

  void _openArticles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ArticlesManageScreen()),
    );
  }

  void _openBilling() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BillingScreen()),
    );
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String _dateLabel(dynamic value) {
    if (value == null || '$value'.isEmpty) return 'Date not available';

    final date = DateTime.tryParse('$value');

    if (date == null) return '$value';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _when(String date, String time) {
    final formattedDate = _dateLabel(date);
    final formattedTime = time.length >= 5 ? time.substring(0, 5) : time;
    return '$formattedDate Ãƒâ€šÃ‚Â· $formattedTime';
  }

  int get _pendingAppointments => _appointments
      .where((item) => item is Map && item['status'] == 'pending')
      .length;

  int get _unreadMessages => _threads.fold<int>(
    0,
    (total, item) => total + (item is Map ? _number(item['unread_count']) : 0),
  );

  int get _openBills => _bills.where((item) {
    if (item is! Map) return false;
    final status = item['status']?.toString().toLowerCase();
    return status == 'unpaid' || status == 'partially_paid';
  }).length;

  int get _unpaidBills => _bills.where((item) {
    if (item is! Map) return false;
    return item['status']?.toString().toLowerCase() == 'unpaid';
  }).length;

  int get _partiallyPaidBills => _bills.where((item) {
    if (item is! Map) return false;
    return item['status']?.toString().toLowerCase() == 'partially_paid';
  }).length;

  Widget _sidebarItem(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool selected = false,
    required bool compact,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? DA.blush : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : 14,
                vertical: 13,
              ),
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(icon, size: 21, color: selected ? DA.rose : DA.sage),
                  if (!compact) ...[
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        label,
                        style: DA.body(
                          14,
                          color: selected ? DA.rose : DA.ink,
                          weight: selected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar({required bool compact}) {
    return Container(
      width: compact ? 76 : 252,
      decoration: BoxDecoration(
        color: DA.surface,
        border: const Border(right: BorderSide(color: DA.divider)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 20,
                vertical: 22,
              ),
              child: compact
                  ? Image.asset(
                      'assets/images/logo/logo.png',
                      height: 38,
                      width: 42,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.favorite_rounded,
                        color: DA.rose,
                        size: 34,
                      ),
                    )
                  : Row(
                      children: [
                        Image.asset(
                          'assets/images/logo/logo.png',
                          height: 38,
                          width: 42,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.favorite_rounded,
                                color: DA.rose,
                                size: 34,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Her Health', style: DA.heading(17)),
                              Text(
                                'Admin Portal',
                                style: DA.body(12, color: DA.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1, color: DA.divider),
            const SizedBox(height: 18),
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MAIN MENU',
                    style: DA.body(
                      10,
                      color: DA.quiet,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _sidebarItem(
                      'Dashboard',
                      Icons.dashboard_outlined,
                      () {},
                      selected: true,
                      compact: compact,
                    ),
                    _sidebarItem(
                      'Patients',
                      Icons.people_outline_rounded,
                      _openPatients,
                      compact: compact,
                    ),
                    _sidebarItem(
                      'Messages',
                      Icons.mail_outline_rounded,
                      _openMessages,
                      compact: compact,
                    ),
                    _sidebarItem(
                      'Articles',
                      Icons.article_outlined,
                      _openArticles,
                      compact: compact,
                    ),
                    _sidebarItem(
                      'Billing',
                      Icons.receipt_long_outlined,
                      _openBilling,
                      compact: compact,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: DA.divider),
            const SizedBox(height: 12),
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOUNT',
                    style: DA.body(
                      10,
                      color: DA.quiet,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            _sidebarItem(
              _deviceUnlockBusy ? 'Enabling device unlock...' : 'Device unlock',
              Icons.fingerprint_rounded,
              _deviceUnlockBusy ? () {} : _enableDeviceUnlock,
              compact: compact,
            ),
            _sidebarItem(
              'Log out',
              Icons.logout_rounded,
              _logout,
              compact: compact,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_sidebarVisible) _buildSidebar(compact: compact),
              Expanded(
                child: RefreshIndicator(
                  color: DA.rose,
                  onRefresh: _loadDashboard,
                  child: _buildBody(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: DA.rose));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final contentWidth = width > 1250 ? 1180.0 : width - 48;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 48),
          children: [
            Center(
              child: SizedBox(
                width: contentWidth.clamp(0.0, 1180.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWelcomeHeader(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 18),
                      _buildWarning(),
                    ],
                    const SizedBox(height: 26),
                    _buildStatistics(width),
                    const SizedBox(height: 32),
                    _buildSectionHeading(
                      'Appointment overview',
                      'Review and manage patient appointment requests.',
                      actionLabel: 'View all patients',
                      onAction: _openPatients,
                    ),
                    const SizedBox(height: 14),
                    _buildAppointmentSection(),
                    const SizedBox(height: 30),
                    _buildSectionHeading(
                      'Messages',
                      'Recent patient conversations and unread messages.',
                      actionLabel: 'Open inbox',
                      onAction: _openMessages,
                    ),
                    const SizedBox(height: 14),
                    _buildMessagesSection(),
                    const SizedBox(height: 30),
                    _buildSectionHeading(
                      'Billing overview',
                      'Keep track of patient payment records.',
                      actionLabel: 'Manage billing',
                      onAction: _openBilling,
                    ),
                    const SizedBox(height: 14),
                    _buildBillingSection(),
                    const SizedBox(height: 30),
                    _buildSectionHeading(
                      'Quick access',
                      'Navigate to the main administration areas.',
                    ),
                    const SizedBox(height: 14),
                    _buildQuickAccess(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        IconButton(
          tooltip: _sidebarVisible ? 'Close sidebar' : 'Open sidebar',
          onPressed: () {
            setState(() {
              _sidebarVisible = !_sidebarVisible;
            });
          },
          icon: Icon(
            _sidebarVisible ? Icons.menu_open_rounded : Icons.menu_rounded,
            color: DA.rose,
            size: 27,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMINISTRATION',
              style: DA.body(12, color: DA.rose, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('$greeting!', style: DA.heading(32)),
            const SizedBox(height: 6),
            Text(
              'Here is an overview of your Her Health portal.',
              style: DA.body(16, color: DA.muted),
            ),
          ],
        ),
        OutlinedButton.icon(
          style: DA.outline().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(130, 46)),
          ),
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DA.pendingBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DA.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: DA.pendingInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: DA.body(13, color: DA.pendingInk),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(double availableWidth) {
    final cardWidth = availableWidth >= 1050
        ? (availableWidth - 54) / 4
        : availableWidth >= 600
        ? (availableWidth - 18) / 2
        : availableWidth;

    final cards = [
      _statCard(
        'Total patients',
        '${_patients.length}',
        'Registered patient profiles',
        Icons.people_alt_outlined,
        DA.sage,
      ),
      _statCard(
        'Pending appointments',
        '$_pendingAppointments',
        'Awaiting a decision',
        Icons.calendar_month_outlined,
        DA.rose,
      ),
      _statCard(
        'Unread messages',
        '$_unreadMessages',
        'Patient messages awaiting a reply',
        Icons.mark_email_unread_outlined,
        DA.pendingInk,
      ),
      _statCard(
        'Open bills',
        '$_openBills',
        'Unpaid or partially paid',
        Icons.receipt_long_outlined,
        DA.sage,
      ),
    ];

    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: cards
          .map((card) => SizedBox(width: cardWidth, child: card))
          .toList(),
    );
  }

  Widget _statCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DA.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: DA.body(14, color: DA.muted, weight: FontWeight.w700),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: DA.heading(32)),
          const SizedBox(height: 4),
          Text(description, style: DA.body(12, color: DA.quiet)),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(
    String title,
    String subtitle, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: DA.heading(22)),
            const SizedBox(height: 4),
            Text(subtitle, style: DA.body(14, color: DA.muted)),
          ],
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: DA.body(14, color: DA.rose, weight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentSection() {
    if (_appointments.isEmpty) {
      return _emptyCard(
        'No appointments to display.',
        Icons.event_available_outlined,
      );
    }

    final recent = _appointments.take(5).toList();

    return Column(
      children: recent.map((item) {
        if (item is! Map) return const SizedBox.shrink();
        return _appointmentCard(Map<String, dynamic>.from(item));
      }).toList(),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status']?.toString() ?? 'pending';
    final firstName = appointment['first_name']?.toString() ?? '';
    final lastName = appointment['last_name']?.toString() ?? '';
    final date = appointment['requested_date']?.toString() ?? '';
    final time = appointment['requested_time']?.toString() ?? '';
    final reason = appointment['reason']?.toString() ?? '';

    final (badgeBg, badgeInk) = _badge(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: DA.card(),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 14,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, minWidth: 240),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DA.initials(firstName, lastName),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 5,
                        children: [
                          Text(
                            '$firstName $lastName'.trim().isEmpty
                                ? 'Patient'
                                : '$firstName $lastName'.trim(),
                            style: DA.body(16, weight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: DA.body(
                                11,
                                color: badgeInk,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _when(date, time),
                        style: DA.body(14, color: DA.muted),
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(reason, style: DA.body(13, color: DA.quiet)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (status == 'pending')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DA.rejectedInk,
                    side: const BorderSide(color: DA.border, width: 1.5),
                    minimumSize: const Size(90, 42),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    final id = _number(appointment['id']);
                    if (id > 0) _updateStatus(id, 'rejected');
                  },
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DA.sage,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(100, 42),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    final id = _number(appointment['id']);
                    if (id > 0) _updateStatus(id, 'approved');
                  },
                  child: const Text('Approve'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  (Color, Color) _badge(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (DA.approvedBg, DA.approvedInk);
      case 'rejected':
      case 'cancelled':
        return (DA.rejectedBg, DA.rejectedInk);
      default:
        return (DA.pendingBg, DA.pendingInk);
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  Widget _buildMessagesSection() {
    if (_threads.isEmpty) {
      return _emptyCard(
        'No patient conversations yet.',
        Icons.mark_email_read_outlined,
      );
    }

    final recent = _threads.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: DA.card(),
      child: Column(
        children: recent.map((item) {
          if (item is! Map) return const SizedBox.shrink();

          final thread = Map<String, dynamic>.from(item);
          final first = thread['first_name']?.toString() ?? '';
          final last = thread['last_name']?.toString() ?? '';
          final unread = _number(thread['unread_count']);
          final preview = thread['last_message']?.toString() ?? '';
          final patientId = _number(thread['patient_id']);

          return ListTile(
            leading: DA.initials(first, last, size: 42),
            title: Text(
              '$first $last'.trim().isEmpty ? 'Patient' : '$first $last'.trim(),
              style: DA.body(15, weight: FontWeight.w800),
            ),
            subtitle: Text(
              preview.isEmpty ? 'No message preview' : preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DA.body(13, color: DA.muted),
            ),
            trailing: unread > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: DA.rose,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$unread',
                      style: DA.body(
                        12,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right_rounded, color: DA.quiet),
            onTap: patientId > 0 ? _openMessages : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBillingSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DA.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: DA.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: DA.rose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment records',
                      style: DA.body(16, weight: FontWeight.w800),
                    ),
                    Text(
                      '${_bills.length} total billing records',
                      style: DA.body(13, color: DA.muted),
                    ),
                  ],
                ),
              ),
              Text('$_openBills open', style: DA.heading(19, color: DA.rose)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: DA.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _billingStatus('Unpaid', _unpaidBills, DA.rejectedInk),
              ),
              Expanded(
                child: _billingStatus(
                  'Partially paid',
                  _partiallyPaidBills,
                  DA.pendingInk,
                ),
              ),
              Expanded(
                child: _billingStatus(
                  'Paid',
                  _bills.length - _openBills,
                  DA.sage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billingStatus(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$count', style: DA.heading(23, color: color)),
        const SizedBox(height: 3),
        Text(label, style: DA.body(12, color: DA.muted)),
      ],
    );
  }

  Widget _buildQuickAccess() {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _quickCard(
          'Patients',
          'View patient profiles',
          Icons.people_outline_rounded,
          _openPatients,
        ),
        _quickCard(
          'Messages',
          'Open patient inbox',
          Icons.mail_outline_rounded,
          _openMessages,
        ),
        _quickCard(
          'Articles',
          '${_articles.length} published records',
          Icons.article_outlined,
          _openArticles,
        ),
        _quickCard(
          'Billing',
          'Manage payment records',
          Icons.receipt_long_outlined,
          _openBilling,
        ),
      ],
    );
  }

  Widget _quickCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 255,
      child: Material(
        color: DA.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: DA.card(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: DA.blush,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: DA.rose),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: DA.body(15, weight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: DA.body(12, color: DA.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: DA.quiet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: DA.card(),
      child: Column(
        children: [
          Icon(icon, size: 30, color: DA.sage),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DA.body(14, color: DA.muted),
          ),
        ],
      ),
    );
  }
}
