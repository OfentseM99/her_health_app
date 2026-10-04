import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AuthService.getReminders();
      if (!mounted) return;
      setState(() {
        _reminders = data.cast<Map<String, dynamic>>();
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

  String _two(int n) => n.toString().padLeft(2, '0');

  String _format(DateTime dt) =>
      '${_two(dt.day)}/${_two(dt.month)}/${dt.year} at ${_two(dt.hour)}:${_two(dt.minute)}';

  Future<void> _toggle(Map<String, dynamic> reminder, bool isDone) async {
    try {
      await AuthService.setReminderDone(reminder['id'] as int, isDone);
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> reminder) async {
    try {
      await AuthService.deleteReminder(reminder['id'] as int);
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddReminderSheet(),
    );

    if (added == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE89CB0),
        title: const Text(
          "Reminders 🔔",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE89CB0),
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.white.withOpacity(0.30)),
          RefreshIndicator(onRefresh: _load, child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }

    if (_reminders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              "No reminders yet.\nTap Add to create one.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        final isDone = reminder['is_done'] == true;
        final title = (reminder['title'] as String?) ?? '';
        final notes = reminder['notes'] as String?;
        final when = DateTime.tryParse((reminder['remind_at'] as String?) ?? '');
        final isOverdue = !isDone && when != null && when.isBefore(now);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            leading: Checkbox(
              value: isDone,
              activeColor: const Color(0xFFE89CB0),
              onChanged: (value) => _toggle(reminder, value ?? false),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.black45 : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (when != null)
                  Text(
                    isOverdue ? '${_format(when)} (overdue)' : _format(when),
                    style: TextStyle(
                      color: isOverdue ? Colors.red.shade400 : Colors.black54,
                    ),
                  ),
                if (notes != null && notes.isNotEmpty)
                  Text(notes, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _delete(reminder),
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet for creating a reminder. Separate widget so it keeps its
/// own form state while open.
class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final titleController = TextEditingController();
  final notesController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isSubmitting = false;

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
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
    if (titleController.text.trim().isEmpty) {
      _showError('Please give the reminder a title.');
      return;
    }
    if (selectedDate == null || selectedTime == null) {
      _showError('Please choose a date and time.');
      return;
    }

    final remindAt = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.addReminder(
        title: titleController.text.trim(),
        notes: notesController.text,
        remindAt: remindAt,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "New Reminder 🔔",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF959B7D),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Title (e.g. Take iron supplement)',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.calendar_today, color: Color(0xFF959B7D)),
            title: Text(
              selectedDate == null
                  ? 'Choose a date'
                  : '${_two(selectedDate!.day)}/${_two(selectedDate!.month)}/${selectedDate!.year}',
            ),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time, color: Color(0xFF959B7D)),
            title: Text(
              selectedTime == null
                  ? 'Choose a time'
                  : selectedTime!.format(context),
            ),
            onTap: _pickTime,
          ),
          TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89CB0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Save Reminder",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
