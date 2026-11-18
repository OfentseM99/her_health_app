import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/design_a.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _isLoading = true;
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
      final data = await AuthService.getMyAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openRequestForm() async {
    final requested = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _RequestAppointmentSheet(),
    );

    if (requested == true) {
      _loadAppointments();
    }
  }

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Background + text colour for a status badge. Colour AND word differ,
  /// so the status reads without relying on colour.
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DA.rose,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const StadiumBorder(),
        onPressed: _openRequestForm,
        icon: const Icon(Icons.add),
        label: Text(
          'Request appointment',
          style: DA.heading(16, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DA.backButton(context),
                  const SizedBox(height: 16),
                  Text('My appointments', style: DA.heading(30)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: DA.rose,
                onRefresh: _loadAppointments,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: DA.rose));
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
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

    if (_appointments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Text(
            'No appointments yet.\nTap "Request appointment" to book one.',
            textAlign: TextAlign.center,
            style: DA.body(16, color: DA.muted),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index] as Map<String, dynamic>;
        final status = appointment['status'] as String? ?? 'pending';
        final dateText = appointment['requested_date'] as String? ?? '';
        final timeText = appointment['requested_time'] as String? ?? '';
        final reason = appointment['reason'] as String?;

        final date = DateTime.tryParse(dateText);
        final time = timeText.length >= 5 ? timeText.substring(0, 5) : timeText;
        final (badgeBg, badgeInk) = _badge(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: DA.card(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 64,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date == null ? '' : _months[date.month - 1],
                      style:
                          DA.body(12, color: badgeInk, weight: FontWeight.w700),
                    ),
                    Text(
                      date == null ? '?' : '${date.day}',
                      style: DA.heading(22),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            date == null
                                ? '$dateText · $time'
                                : '${_weekdays[date.weekday - 1]} · $time',
                            style: DA.body(16, weight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.isEmpty
                                ? status
                                : status[0].toUpperCase() + status.substring(1),
                            style: DA.body(12,
                                color: badgeInk, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(reason, style: DA.body(14, color: DA.muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The bottom sheet form for requesting a new appointment. Kept as a
/// separate widget rather than a method, since it needs its own state
/// (selected date/time, submitting flag) independent of the list screen.
class _RequestAppointmentSheet extends StatefulWidget {
  const _RequestAppointmentSheet();

  @override
  State<_RequestAppointmentSheet> createState() =>
      _RequestAppointmentSheetState();
}

class _RequestAppointmentSheetState extends State<_RequestAppointmentSheet> {
  final reasonController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isSubmitting = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date and time.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final dateStr =
        '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';

    try {
      await AuthService.requestAppointment(
        date: dateStr,
        time: timeStr,
        reason: reasonController.text,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: Colors.red.shade400),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Request an appointment', style: DA.heading(22)),
          const SizedBox(height: 16),
          DA.label('Date'),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: DA.input(
                suffix:
                    const Icon(Icons.calendar_today_outlined, color: DA.sage),
              ),
              child: Text(
                selectedDate == null
                    ? 'Choose a date'
                    : '${two(selectedDate!.day)}/${two(selectedDate!.month)}/${selectedDate!.year}',
                style: DA.body(16,
                    color: selectedDate == null ? DA.quiet : DA.ink),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DA.label('Time'),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickTime,
            child: InputDecorator(
              decoration: DA.input(
                suffix: const Icon(Icons.access_time_rounded, color: DA.sage),
              ),
              child: Text(
                selectedTime == null
                    ? 'Choose a time'
                    : selectedTime!.format(context),
                style: DA.body(16,
                    color: selectedTime == null ? DA.quiet : DA.ink),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DA.label('Reason (optional)'),
          TextField(
            controller: reasonController,
            style: DA.body(16),
            decoration: DA.input(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: DA.primary(),
            onPressed: _isSubmitting ? null : _submit,
            child:
                _isSubmitting ? DA.buttonSpinner : const Text('Send request'),
          ),
        ],
      ),
    );
  }
}
