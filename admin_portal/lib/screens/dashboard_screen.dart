import 'dart:convert';

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

  String? _errorMessage;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.authorizedGet('/appointments/all');

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleSessionExpired();
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage =
              'Failed to load appointments (${response.statusCode}).';
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body) as List<dynamic>;

      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not reach the server.';
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
    final response = await ApiService.authorizedPut(
      '/appointments/$appointmentId/status',
      {'status': status},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      _loadAppointments();
    } else {
      _showMessage(
        'Failed to update appointment (${response.statusCode}).',
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

  static const _months = [
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

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _when(String date, String time) {
    final d = DateTime.tryParse(date);

    final t = time.length >= 5 ? time.substring(0, 5) : time;

    if (d == null) {
      return '$date · $t';
    }

    return '${_weekdays[d.weekday - 1]} '
        '${d.day} ${_months[d.month - 1]} '
        '${d.year} · $t';
  }

  (Color, Color) _badge(String status) {
    switch (status) {
      case 'approved':
        return (DA.approvedBg, DA.approvedInk);

      case 'rejected':
      case 'cancelled':
        return (DA.rejectedBg, DA.rejectedInk);

      default:
        return (DA.pendingBg, DA.pendingInk);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      appBar: DA.adminBar(
        'Her Health',
        showBack: false,
        titleWidget: Row(
          children: [
            Image.asset(
              'assets/images/logo/logo.png',
              height: 32,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),

            const SizedBox(width: 10),

            Text('Her Health', style: DA.heading(20)),

            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DA.blush,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: DA.body(
                  12,
                  color: DA.rejectedInk,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          DA.barLink(Icons.people_outline_rounded, 'Patients', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PatientsScreen()),
            );
          }),

          DA.barLink(Icons.mail_outline_rounded, 'Messages', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MessagesInboxScreen(),
              ),
            );
          }),

          DA.barLink(Icons.article_outlined, 'Articles', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ArticlesManageScreen(),
              ),
            );
          }),

          DA.barLink(Icons.receipt_long_outlined, 'Billing', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BillingScreen()),
            );
          }),

          const SizedBox(width: 8),

          OutlinedButton.icon(
            style: DA.outline().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(170, 44)),
            ),
            onPressed: _deviceUnlockBusy ? null : _enableDeviceUnlock,
            icon: _deviceUnlockBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DA.rose,
                    ),
                  )
                : const Icon(Icons.fingerprint_rounded),
            label: Text(_deviceUnlockBusy ? 'Enabling...' : 'Device unlock'),
          ),

          const SizedBox(width: 8),

          OutlinedButton(
            style: DA.outline().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(100, 44)),
            ),
            onPressed: _logout,
            child: const Text('Log out'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: DA.rose,
        onRefresh: _loadAppointments,
        child: _buildBody(),
      ),
    );
  }

  Widget _header() {
    final pending = _appointments
        .where((a) => (a as Map<String, dynamic>)['status'] == 'pending')
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appointments', style: DA.heading(30)),
          const SizedBox(height: 6),
          Text(
            pending == 0
                ? 'No requests waiting for a decision.'
                : '$pending ${pending == 1 ? 'request is' : 'requests are'} waiting for a decision.',
            style: DA.body(16, color: DA.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: DA.rose));
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),

          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: DA.body(15, color: DA.rejectedInk),
          ),

          const SizedBox(height: 16),

          Center(
            child: OutlinedButton(
              style: DA.outline().copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(140, 48)),
              ),
              onPressed: _loadAppointments,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      children: [
        DA.page(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),

              if (_appointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: DA.card(),
                  child: Text(
                    'No appointments yet.',
                    textAlign: TextAlign.center,
                    style: DA.body(16, color: DA.muted),
                  ),
                ),

              ..._appointments.map(
                (a) => _appointmentCard(a as Map<String, dynamic>),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] as String? ?? 'pending';

    final firstName = appointment['first_name'] as String? ?? '';

    final lastName = appointment['last_name'] as String? ?? '';

    final date = appointment['requested_date'] as String? ?? '';

    final time = appointment['requested_time'] as String? ?? '';

    final reason = appointment['reason'] as String?;

    final (badgeBg, badgeInk) = _badge(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: DA.card(),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 520),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '$firstName $lastName'.trim(),
                              style: DA.body(17, weight: FontWeight.w700),
                            ),
                          ),

                          const SizedBox(width: 10),

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
                              status.isEmpty
                                  ? status
                                  : status[0].toUpperCase() +
                                        status.substring(1),
                              style: DA.body(
                                12,
                                color: badgeInk,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _when(date, time),
                        style: DA.body(15, color: DA.muted),
                      ),

                      if (reason != null && reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(reason, style: DA.body(15, color: DA.quiet)),
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
                    minimumSize: const Size(110, 44),
                    shape: const StadiumBorder(),
                    textStyle: DA.body(15, weight: FontWeight.w700),
                  ),
                  onPressed: () =>
                      _updateStatus(appointment['id'] as int, 'rejected'),
                  child: const Text('Reject'),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DA.sage,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(110, 44),
                    shape: const StadiumBorder(),
                    textStyle: DA.body(15, weight: FontWeight.w700),
                  ),
                  onPressed: () =>
                      _updateStatus(appointment['id'] as int, 'approved'),
                  child: const Text('Approve'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
