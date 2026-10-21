import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/design_a.dart';

class HealthTrackingScreen extends StatefulWidget {
  const HealthTrackingScreen({super.key});

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> {
  final journalController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  String? _mood;
  String? _painLevel;

  bool _loading = true;
  bool _saving = false;

  List<dynamic> _entries = [];

  final Set<String> _selectedSymptoms = {};

  static const moods = [
    'Great',
    'Good',
    'Okay',
    'Low',
    'Very low',
  ];

  static const painLevels = [
    'None',
    'Mild',
    'Moderate',
    'Strong',
    'Severe',
  ];

  static const symptoms = [
    'Cramps',
    'Headache',
    'Bloating',
    'Fatigue',
    'Nausea',
    'Back pain',
    'Breast tenderness',
    'Mood changes',
    'Dizziness',
    'Sleep problems',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    journalController.dispose();
    super.dispose();
  }

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _prettyDate(DateTime date) {
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

  Future<void> _loadEntries() async {
    try {
      final entries = await AuthService.getHealthTrackingEntries();

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(e.toString(), isError: true);
    }
  }

  List<dynamic> get _entriesForSelectedDay {
    final selected = _dateString(_selectedDate);

    return _entries.where((entry) {
      return entry is Map && entry['entry_date'] == selected;
    }).toList();
  }

  int get _entriesThisMonth {
    return _entries.where((entry) {
      if (entry is! Map) return false;

      final date = DateTime.tryParse(entry['entry_date']?.toString() ?? '');

      if (date == null) return false;

      final now = DateTime.now();

      return date.year == now.year && date.month == now.month;
    }).length;
  }

  String get _mostCommonMood {
    final counts = <String, int>{};

    for (final entry in _entries) {
      if (entry is! Map) continue;

      final mood = entry['mood']?.toString();

      if (mood == null || mood.isEmpty) continue;

      counts[mood] = (counts[mood] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return 'No mood data yet';
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  Future<void> _saveEntry() async {
    if (_mood == null &&
        _painLevel == null &&
        _selectedSymptoms.isEmpty &&
        journalController.text.trim().isEmpty) {
      _showMessage(
        'Add at least one health detail before saving.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await AuthService.saveHealthTrackingEntry(
        entryDate: _dateString(_selectedDate),
        painLevel: _painLevel,
        mood: _mood,
        data: {
          'symptoms': _selectedSymptoms.toList(),
          'journal': journalController.text.trim(),
        },
      );

      journalController.clear();

      setState(() {
        _mood = null;
        _painLevel = null;
        _selectedSymptoms.clear();
      });

      await _loadEntries();

      if (!mounted) return;

      _showMessage('Health entry saved 🌸');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : null,
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DA.heading(20, color: DA.sage),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: DA.body(13, color: DA.quiet),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insightCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: DA.card(color: DA.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: DA.rose,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: DA.heading(20),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: DA.body(
                12,
                color: DA.quiet,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(dynamic entry) {
    final data = entry is Map ? entry['data'] : null;

    final symptoms = data is Map && data['symptoms'] is List
        ? (data['symptoms'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final journal = data is Map ? (data['journal']?.toString() ?? '') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: DA.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry['mood'] != null)
            Text(
              'Mood: ${entry['mood']}',
              style: DA.body(
                15,
                weight: FontWeight.w700,
              ),
            ),
          if (entry['pain_level'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Pain / cramps: ${entry['pain_level']}',
              style: DA.body(15),
            ),
          ],
          if (symptoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: symptoms
                  .map(
                    (symptom) => Chip(
                      label: Text(symptom),
                      backgroundColor: DA.blush,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (journal.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              journal,
              style: DA.body(14, color: DA.muted),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DA.rose,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DA.backButton(context),
                        const SizedBox(height: 16),
                        Text(
                          'Health tracking',
                          style: DA.heading(30),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track how you feel, record symptoms and keep private health notes.',
                          style: DA.body(
                            15,
                            color: DA.muted,
                          ),
                        ),
                        _sectionTitle(
                          'Health insights',
                          subtitle:
                              'A simple summary based on your recorded entries.',
                        ),
                        Row(
                          children: [
                            _insightCard(
                              icon: Icons.calendar_month_rounded,
                              value: '$_entriesThisMonth',
                              title: 'Entries this month',
                            ),
                            const SizedBox(width: 12),
                            _insightCard(
                              icon: Icons.mood_rounded,
                              value: _mostCommonMood,
                              title: 'Most recorded mood',
                            ),
                          ],
                        ),
                        _sectionTitle(
                          'Calendar',
                          subtitle:
                              'Select a day to view or add a health entry.',
                        ),
                        Container(
                          decoration: DA.card(),
                          child: CalendarDatePicker(
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            onDateChanged: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _prettyDate(_selectedDate),
                          style: DA.heading(
                            18,
                            color: DA.rose,
                          ),
                        ),
                        _sectionTitle('How are you feeling?'),
                        DA.label('Mood'),
                        DropdownButtonFormField<String>(
                          initialValue: _mood,
                          decoration: DA.input(
                            hint: 'Select your mood',
                          ),
                          items: moods
                              .map(
                                (mood) => DropdownMenuItem(
                                  value: mood,
                                  child: Text(mood),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _mood = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DA.label('Pain / cramps'),
                        DropdownButtonFormField<String>(
                          initialValue: _painLevel,
                          decoration: DA.input(
                            hint: 'Select pain level',
                          ),
                          items: painLevels
                              .map(
                                (pain) => DropdownMenuItem(
                                  value: pain,
                                  child: Text(pain),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _painLevel = value;
                            });
                          },
                        ),
                        _sectionTitle(
                          'Symptoms',
                          subtitle: 'Choose any symptoms you experienced.',
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: symptoms.map((symptom) {
                            final selected =
                                _selectedSymptoms.contains(symptom);

                            return FilterChip(
                              selected: selected,
                              label: Text(symptom),
                              selectedColor: DA.blush,
                              checkmarkColor: DA.rose,
                              side: BorderSide(
                                color: selected ? DA.rose : DA.border,
                              ),
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _selectedSymptoms.add(symptom);
                                  } else {
                                    _selectedSymptoms.remove(symptom);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        _sectionTitle(
                          'Journal',
                          subtitle:
                              'Add anything you want to remember about today.',
                        ),
                        TextField(
                          controller: journalController,
                          minLines: 4,
                          maxLines: 7,
                          decoration: DA.input(
                            hint:
                                'How did you feel today? Add symptoms, changes or notes...',
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: DA.primary(),
                          onPressed: _saving ? null : _saveEntry,
                          icon: _saving
                              ? const SizedBox.shrink()
                              : const Icon(
                                  Icons.favorite_outline_rounded,
                                ),
                          label: _saving
                              ? DA.buttonSpinner
                              : const Text('Save health entry'),
                        ),
                        _sectionTitle(
                          'Entries for this day',
                        ),
                        if (_entriesForSelectedDay.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: DA.card(),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.menu_book_outlined,
                                  size: 34,
                                  color: DA.sage,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No health entries recorded for this day.',
                                  textAlign: TextAlign.center,
                                  style: DA.body(
                                    14,
                                    color: DA.quiet,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._entriesForSelectedDay.map(
                            _entryCard,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
