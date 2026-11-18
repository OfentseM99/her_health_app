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
  final Map<String, TextEditingController> _fieldControllers = {};

  DateTime? _periodLogStartDate;
  String _periodFlow = 'Moderate';

  DateTime _selectedDate = DateTime.now();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  String? _mood;
  String? _painLevel;

  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic>? _journey;
  List<dynamic> _entries = [];

  final Set<String> _selectedSymptoms = {};

  static const moods = ['Great', 'Good', 'Okay', 'Low', 'Very low'];

  static const painLevels = ['None', 'Mild', 'Moderate', 'Strong', 'Severe'];

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

  static const _babyWeeks = <int, Map<String, String>>{
    8: {
      'size': '1.6 cm',
      'weight': '1 g',
      'comparison': 'raspberry',
      'development':
          'Your baby is developing tiny arms and legs. The heart is beating and important organs are beginning to form.'
    },
    9: {
      'size': '2.3 cm',
      'weight': '2 g',
      'comparison': 'cherry',
      'development':
          'Facial features are becoming more recognisable, and the arms and legs are growing.'
    },
    10: {
      'size': '3.1 cm',
      'weight': '4 g',
      'comparison': 'strawberry',
      'development':
          'The major organs have begun forming. Tiny fingers and toes are developing.'
    },
    12: {
      'size': '5.4 cm',
      'weight': '14 g',
      'comparison': 'plum',
      'development':
          'Your baby is moving, and facial features are becoming more defined.'
    },
    14: {
      'size': '8.7 cm',
      'weight': '43 g',
      'comparison': 'lemon',
      'development':
          'Your baby is growing quickly. The neck is becoming more defined and facial movements are developing.'
    },
    16: {
      'size': '11.6 cm',
      'weight': '100 g',
      'comparison': 'avocado',
      'development':
          'Your baby is moving arms and legs. The eyes and ears are moving towards their usual positions.'
    },
    18: {
      'size': '14.2 cm',
      'weight': '190 g',
      'comparison': 'bell pepper',
      'development':
          'Your baby is developing hearing and practising movements such as bending the arms and legs.'
    },
    20: {
      'size': '16.4 cm',
      'weight': '300 g',
      'comparison': 'banana',
      'development':
          'Your baby is growing hair, and the skin is developing protective layers. Movements may become easier to notice.'
    },
    22: {
      'size': '19 cm',
      'weight': '430 g',
      'comparison': 'papaya',
      'development':
          'Your baby is developing sensory responses and continues practising movements.'
    },
    24: {
      'size': '21 cm',
      'weight': '600 g',
      'comparison': 'corn cob',
      'development':
          'The lungs are developing, and your baby is responding to sounds and movement.'
    },
    26: {
      'size': '23 cm',
      'weight': '760 g',
      'comparison': 'lettuce',
      'development':
          'Your baby is becoming more active. The brain and lungs continue to mature.'
    },
    28: {
      'size': '25 cm',
      'weight': '1 kg',
      'comparison': 'eggplant',
      'development':
          'Your baby is opening their eyes and continuing to gain weight.'
    },
    30: {
      'size': '27 cm',
      'weight': '1.3 kg',
      'comparison': 'cabbage',
      'development':
          'The brain is developing rapidly, and your baby is gaining more body fat.'
    },
    32: {
      'size': '28 cm',
      'weight': '1.7 kg',
      'comparison': 'squash',
      'development':
          'Your baby is continuing to practise breathing movements and build strength.'
    },
    34: {
      'size': '30 cm',
      'weight': '2.1 kg',
      'comparison': 'cantaloupe',
      'development':
          'The lungs and nervous system continue maturing as your baby gains weight.'
    },
    36: {
      'size': '32 cm',
      'weight': '2.6 kg',
      'comparison': 'romaine lettuce',
      'development':
          'Your baby is getting bigger and may begin moving into a head-down position.'
    },
    38: {
      'size': '34 cm',
      'weight': '3 kg',
      'comparison': 'pumpkin',
      'development':
          'Your baby is approaching full term and continuing to prepare for birth.'
    },
    40: {
      'size': '36 cm',
      'weight': '3.4 kg',
      'comparison': 'watermelon',
      'development':
          'Your baby is around the expected due date. Individual birth timing and size vary.'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  @override
  void dispose() {
    journalController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _journeyType => _journey?['journey_type']?.toString() ?? '';

  Map<String, dynamic> get _answers {
    final value = _journey?['answers'];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

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
        return 'Health Tracking';
    }
  }

  String get _journeyDescription {
    switch (_journeyType) {
      case 'pregnancy_care':
        return 'Follow your pregnancy journey, milestones and antenatal notes.';
      case 'menstrual_health':
        return 'Understand your cycle and record period experiences.';
      case 'postpartum_recovery':
        return 'Follow your recovery and wellbeing after delivery.';
      case 'general_health':
        return 'Build a record of your everyday health and wellness.';
      case 'cosmetic_gynecology':
        return 'Track your procedure recovery and clinician aftercare.';
      default:
        return 'Record your health experiences and personal notes.';
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final parts = text.split(RegExp(r'[/.-]'));
    if (parts.length != 3) return null;

    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);

    if (a == null || b == null || c == null) return null;

    int year;
    int month;
    int day;

    if (parts[0].length == 4) {
      year = a;
      month = b;
      day = c;
    } else {
      day = a;
      month = b;
      year = c < 100 ? 2000 + c : c;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final result = DateTime(year, month, day);
    if (result.year != year || result.month != month || result.day != day) {
      return null;
    }
    return result;
  }

  String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
      'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  TextEditingController _controllerFor(String key) =>
      _fieldControllers.putIfAbsent(key, () => TextEditingController());

  DateTime? get _pregnancyDueDate => _parseDate(_answers['due_date']);

  DateTime? get _pregnancyStartDate {
    final due = _pregnancyDueDate;
    if (due != null) return due.subtract(const Duration(days: 280));

    final weeks = int.tryParse(_answers['weeks_pregnant']?.toString() ?? '');
    final created = _parseDate(_journey?['created_at']);
    if (weeks == null || created == null) return null;

    return created.subtract(Duration(days: weeks * 7));
  }

  int? _pregnancyDaysOn(DateTime date) {
    final start = _pregnancyStartDate;
    if (start == null) return null;

    final selected = DateTime(date.year, date.month, date.day);
    final pregnancyStart = DateTime(start.year, start.month, start.day);
    final days = selected.difference(pregnancyStart).inDays;

    return days < 0 ? null : days;
  }

  int? _pregnancyWeekOn(DateTime date) {
    final days = _pregnancyDaysOn(date);
    if (days == null) return null;
    return (days ~/ 7).clamp(0, 42).toInt();
  }

  int? _pregnancyDayOn(DateTime date) {
    final days = _pregnancyDaysOn(date);
    if (days == null) return null;
    return days % 7;
  }

  int? get _pregnancyWeek => _pregnancyWeekOn(DateTime.now());

  int? get _pregnancyDay => _pregnancyDayOn(DateTime.now());
  int? get _postpartumDays {
    final weeks = int.tryParse(
      _answers['weeks_postpartum']?.toString() ?? '',
    );
    final created = _parseDate(_journey?['created_at']);
    if (weeks == null || created == null) return null;
    final start = created.subtract(Duration(days: weeks * 7));
    return DateTime.now().difference(start).inDays.clamp(0, 5000);
  }

  int? get _postpartumWeek {
    final days = _postpartumDays;
    return days == null ? null : days ~/ 7;
  }

  int? get _cycleLength {
    final raw = _answers['cycle_length']?.toString().trim() ?? '';

    // Only use an exact numeric cycle length.
    // Answers such as "Less than 21 days", "More than 35 days"
    // and "I don't know" do not provide an exact value.
    final match =
        RegExp(r'^(\d+)\s*days?$', caseSensitive: false).firstMatch(raw);

    if (match == null) return null;

    final value = int.tryParse(match.group(1) ?? '');
    if (value == null || value < 15 || value > 60) return null;

    return value;
  }

  int get _periodLength {
    final raw = _answers['period_length']?.toString().trim() ?? '';

    // Extract the number from answers such as "5 days".
    final match =
        RegExp(r'^(\d+)\s*days?$', caseSensitive: false).firstMatch(raw);

    final value = int.tryParse(match?.group(1) ?? '');

    // Five days is a clearly disclosed fallback estimate when
    // the user does not know their average period duration.
    if (value == null || value < 1 || value > 10) return 5;

    return value;
  }

  bool get _hasKnownPeriodLength {
    final raw = _answers['period_length']?.toString().trim() ?? '';
    final match =
        RegExp(r'^(\d+)\s*days?$', caseSensitive: false).firstMatch(raw);
    final value = int.tryParse(match?.group(1) ?? '');

    return value != null && value >= 1 && value <= 10;
  }

  DateTime? get _lastPeriodDate {
    DateTime? latest = _parseDate(_answers['last_period']);

    for (final entry in _entries) {
      if (entry is! Map) continue;

      final data = entry['data'];
      if (data is! Map) continue;

      DateTime? candidate;

      final menstrualLog = data['menstrual_log'];
      if (menstrualLog is Map) {
        candidate = _parseDate(menstrualLog['start_date']);
      }

      if (candidate == null) {
        final fields = data['journey_fields'];
        if (fields is Map) {
          candidate = _parseDate(fields['period_start_date']);
        }
      }

      if (candidate != null && (latest == null || candidate.isAfter(latest))) {
        latest = candidate;
      }
    }

    return latest;
  }

  // Finds the next logged period start after a given date.
  // Used to prevent an older estimated period from extending
  // into a newer period that the user has logged.
  DateTime? _nextLoggedPeriodStartAfter(DateTime start) {
    DateTime? nextStart;

    for (final entry in _entries) {
      if (entry is! Map) continue;

      final data = entry['data'];
      if (data is! Map) continue;

      DateTime? candidate;
      final menstrualLog = data['menstrual_log'];

      if (menstrualLog is Map) {
        candidate = _parseDate(menstrualLog['start_date']);
      }

      if (candidate == null) {
        final fields = data['journey_fields'];
        if (fields is Map) {
          candidate = _parseDate(fields['period_start_date']);
        }
      }

      if (candidate == null || !candidate.isAfter(start)) {
        continue;
      }

      if (nextStart == null || candidate.isBefore(nextStart)) {
        nextStart = candidate;
      }
    }

    return nextStart;
  }

  List<Map<String, String>> get _journeyFields {
    switch (_journeyType) {
      case 'pregnancy_care':
        return [
          {
            'key': 'pregnancy_appointment',
            'label': 'Antenatal appointment',
            'hint': 'Record an appointment, date or outcome'
          },
          {
            'key': 'pregnancy_milestone',
            'label': 'Pregnancy milestone',
            'hint': 'Record a milestone or change you noticed'
          },
          {
            'key': 'pregnancy_notes',
            'label': 'Pregnancy notes',
            'hint': 'Any other pregnancy-related notes...'
          },
        ];
      case 'menstrual_health':
        return [
          {
            'key': 'menstrual_flow',
            'label': 'Menstrual flow',
            'hint': 'Light, moderate or heavy'
          },
          {
            'key': 'cycle_notes',
            'label': 'Cycle notes',
            'hint': 'Record changes or anything unusual'
          },
        ];
      case 'postpartum_recovery':
        return [
          {
            'key': 'postpartum_recovery_notes',
            'label': 'Recovery experience',
            'hint': 'Describe how your recovery is going'
          },
          {
            'key': 'postpartum_sleep',
            'label': 'Sleep',
            'hint': 'Record your sleep or rest'
          },
          {
            'key': 'postpartum_breastfeeding',
            'label': 'Breastfeeding (optional)',
            'hint': 'Record any breastfeeding notes'
          },
          {
            'key': 'postpartum_followup',
            'label': 'Follow-up appointment',
            'hint': 'Record your next appointment or outcome'
          },
        ];
      case 'general_health':
        return [
          {
            'key': 'water_intake',
            'label': 'Water intake',
            'hint': 'e.g. 6 glasses or 1.5 litres'
          },
          {
            'key': 'exercise',
            'label': 'Physical activity',
            'hint': 'Describe your activity or exercise'
          },
          {'key': 'sleep_hours', 'label': 'Sleep', 'hint': 'e.g. 7 hours'},
          {
            'key': 'weight',
            'label': 'Weight (optional)',
            'hint': 'Enter your weight if you want to track it'
          },
          {
            'key': 'general_health_notes',
            'label': 'Wellness notes',
            'hint': 'Any other health or wellness notes...'
          },
        ];
      case 'cosmetic_gynecology':
        return [
          {
            'key': 'procedure_name',
            'label': 'Procedure',
            'hint': 'Enter the procedure name'
          },
          {
            'key': 'procedure_date',
            'label': 'Procedure date',
            'hint': 'YYYY-MM-DD'
          },
          {
            'key': 'clinician_instructions',
            'label': 'Clinician aftercare instructions',
            'hint': 'Record the instructions given by your clinician'
          },
          {
            'key': 'medication_notes',
            'label': 'Medication notes',
            'hint': 'Record prescribed medication or reminders'
          },
          {
            'key': 'followup_date',
            'label': 'Follow-up date',
            'hint': 'YYYY-MM-DD'
          },
          {
            'key': 'recovery_notes',
            'label': 'Recovery progress',
            'hint': 'Record your experience and progress'
          },
        ];
      default:
        return [];
    }
  }

  Future<void> _loadTrackingData() async {
    setState(() => _loading = true);
    try {
      final journey = await AuthService.getHealthJourney();
      if (!mounted) return;

      if (journey == null) {
        setState(() {
          _journey = null;
          _entries = [];
          _loading = false;
        });
        return;
      }

      final id = int.tryParse(journey['id'].toString());
      final entries = await AuthService.getHealthTrackingEntries(journeyId: id);
      if (!mounted) return;

      setState(() {
        _journey = journey;
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(e.toString(), isError: true);
    }
  }

  List<dynamic> get _entriesForSelectedDay {
    return _entries.where((entry) {
      if (entry is! Map) return false;
      final date = _parseDate(entry['entry_date']);
      return date != null && _sameDay(date, _selectedDate);
    }).toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int get _entriesThisMonth => _entries.where((entry) {
        if (entry is! Map) return false;
        final date = _parseDate(entry['entry_date']);
        return date != null &&
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month;
      }).length;

  String get _mostCommonMood {
    final counts = <String, int>{};
    for (final entry in _entries) {
      if (entry is! Map) continue;
      final mood = entry['mood']?.toString();
      if (mood != null && mood.isNotEmpty) {
        counts[mood] = (counts[mood] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'No mood data';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<Map<String, dynamic>> get _events {
    final result = <Map<String, dynamic>>[];

    void add(DateTime? date, String type, String title, String detail) {
      if (date == null) return;

      result.add({
        'date': DateTime(date.year, date.month, date.day),
        'type': type,
        'title': title,
        'detail': detail,
      });
    }

    void addPeriodRange(
      DateTime start,
      DateTime end,
      String type,
      String title,
      String detail,
    ) {
      var date = DateTime(start.year, start.month, start.day);
      final last = DateTime(end.year, end.month, end.day);

      while (!date.isAfter(last)) {
        add(date, type, title, detail);
        date = date.add(const Duration(days: 1));
      }
    }

    // PREGNANCY CALENDAR
    if (_journeyType == 'pregnancy_care') {
      final due = _pregnancyDueDate;
      final start = _pregnancyStartDate;

      if (due != null) {
        add(
          due,
          'milestone',
          'Estimated due date',
          'Your estimated due date. Birth timing varies.',
        );
      }

      if (start != null) {
        for (int week = 1; week <= 40; week++) {
          add(
            start.add(Duration(days: week * 7)),
            'milestone',
            'Pregnancy week $week',
            'You reach $week completed weeks of pregnancy.',
          );
        }
      }
    }

    // POSTPARTUM CALENDAR
    if (_journeyType == 'postpartum_recovery') {
      final weeks = int.tryParse(
        _answers['weeks_postpartum']?.toString() ?? '',
      );
      final created = _parseDate(_journey?['created_at']);

      if (weeks != null && created != null) {
        final estimatedStart = created.subtract(Duration(days: weeks * 7));

        for (int week = 1; week <= 52; week++) {
          add(
            estimatedStart.add(Duration(days: week * 7)),
            'recovery_milestone',
            'Postpartum week $week',
            'Approximate recovery-week marker based on your saved setup.',
          );
        }
      }
    }

    // MENSTRUAL CALENDAR: PREDICTED EVENTS
    if (_journeyType == 'menstrual_health') {
      final last = _lastPeriodDate;
      final cycle = _cycleLength;

      if (last != null && cycle != null) {
        // Start predictions with the next cycle, not the
        // actual period that has already been recorded.
        for (int i = 1; i <= 6; i++) {
          final start = last.add(Duration(days: cycle * i));

          for (int day = 0; day < _periodLength; day++) {
            add(
              start.add(Duration(days: day)),
              'period',
              'Estimated period',
              'Predicted period date based on your saved cycle length.',
            );
          }

          // Ovulation is estimated approximately 14 days
          // BEFORE the predicted next period starts.
          final ovulation = start.subtract(
            const Duration(days: 14),
          );

          add(
            ovulation,
            'ovulation',
            'Estimated ovulation',
            'Ovulation timing is an estimate and can vary.',
          );

          for (int day = -5; day <= 1; day++) {
            if (day == 0) continue;

            add(
              ovulation.add(Duration(days: day)),
              'fertile',
              'Estimated fertile window',
              'This is an estimate and must not be used as contraception.',
            );
          }
        }
      }
    }

    // SAVED ENTRIES FOR ALL JOURNEYS
    for (final entry in _entries) {
      if (entry is! Map) continue;

      final entryDate = _parseDate(entry['entry_date']);
      final data = entry['data'];

      if (data is! Map) continue;

      final fields = data['journey_fields'];
      final journeyFields = fields is Map ? fields : <dynamic, dynamic>{};

      // ACTUAL AND ESTIMATED MENSTRUAL PERIOD DAYS
      if (_journeyType == 'menstrual_health') {
        final log = data['menstrual_log'];

        if (log is Map) {
          final start = _parseDate(log['start_date']);

          if (start != null) {
            final savedEnd = _parseDate(log['end_date']);
            final savedDuration = int.tryParse(
              log['period_length']?.toString() ?? '',
            );

            // Older records with a manually recorded end date
            // remain displayed as historical recorded periods.
            if (savedEnd != null && !savedEnd.isBefore(start)) {
              addPeriodRange(
                start,
                savedEnd,
                'logged_period',
                'Logged period',
                'Previously recorded period: ${log['flow'] ?? 'Flow not specified'} flow.',
              );
            } else {
              // New records confirm Day 1 only.
              // Remaining days are estimates from the saved average.
              final duration = savedDuration != null &&
                      savedDuration >= 1 &&
                      savedDuration <= 10
                  ? savedDuration
                  : _periodLength;

              final nextStart = _nextLoggedPeriodStartAfter(start);
              final daysUntilNextStart = nextStart?.difference(start).inDays;

              final visibleDays =
                  daysUntilNextStart != null && daysUntilNextStart < duration
                      ? daysUntilNextStart
                      : duration;

              for (int day = 0; day < visibleDays; day++) {
                final date = start.add(Duration(days: day));

                add(
                  date,
                  day == 0 ? 'logged_period' : 'period',
                  day == 0 ? 'Period started' : 'Expected period',
                  day == 0
                      ? 'You logged the start of your period.'
                      : (log['period_length_is_estimate'] == true
                          ? 'Estimated period day ${day + 1} of $duration, using a temporary five-day estimate because your average duration is unknown.'
                          : 'Estimated period day ${day + 1} of $duration, based on your saved average period duration.'),
                );
              }
            }
          }
        } else {
          // Retain compatibility with older journey_fields entries.
          final start = _parseDate(
            journeyFields['period_start_date'],
          );
          final end = _parseDate(
            journeyFields['period_end_date'],
          );

          if (start != null) {
            final nextStart = _nextLoggedPeriodStartAfter(start);

            final estimatedEnd = start.add(
              Duration(days: _periodLength - 1),
            );

            final cappedEstimatedEnd =
                nextStart != null && nextStart.isBefore(estimatedEnd)
                    ? nextStart.subtract(const Duration(days: 1))
                    : estimatedEnd;

            addPeriodRange(
              start,
              end != null && !end.isBefore(start) ? end : cappedEstimatedEnd,
              'logged_period',
              'Recorded period',
              'Period dates saved in an earlier tracking entry.',
            );
          }
        }
      }
      // Pregnancy appointments and recorded milestones
      if (_journeyType == 'pregnancy_care' && entryDate != null) {
        final appointment =
            journeyFields['pregnancy_appointment']?.toString().trim() ?? '';

        final milestone =
            journeyFields['pregnancy_milestone']?.toString().trim() ?? '';

        if (appointment.isNotEmpty) {
          add(
            entryDate,
            'appointment',
            'Antenatal appointment recorded',
            appointment,
          );
        }

        if (milestone.isNotEmpty) {
          add(
            entryDate,
            'milestone',
            'Pregnancy milestone recorded',
            milestone,
          );
        }
      }

      // Postpartum recovery entries
      if (_journeyType == 'postpartum_recovery' && entryDate != null) {
        final recovery =
            journeyFields['postpartum_recovery_notes']?.toString().trim() ?? '';

        final followup =
            journeyFields['postpartum_followup']?.toString().trim() ?? '';

        if (recovery.isNotEmpty ||
            followup.isNotEmpty ||
            data['journal']?.toString().trim().isNotEmpty == true) {
          add(
            entryDate,
            'recovery',
            'Postpartum recovery check-in',
            recovery.isNotEmpty
                ? recovery
                : 'You recorded a postpartum recovery update.',
          );
        }

        if (followup.isNotEmpty) {
          add(
            entryDate,
            'appointment',
            'Postpartum follow-up noted',
            followup,
          );
        }
      }

      // General health and wellness entries
      if (_journeyType == 'general_health' && entryDate != null) {
        final hasWellnessData = [
          'water_intake',
          'exercise',
          'sleep_hours',
          'weight',
          'general_health_notes',
        ].any(
            (key) => journeyFields[key]?.toString().trim().isNotEmpty == true);

        if (hasWellnessData ||
            data['journal']?.toString().trim().isNotEmpty == true) {
          add(
            entryDate,
            'wellness',
            'Wellness activity recorded',
            'Your health and wellness information was saved.',
          );
        }
      }

      // Cosmetic gynaecology procedure and follow-up dates
      if (_journeyType == 'cosmetic_gynecology') {
        final procedureDate = _parseDate(journeyFields['procedure_date']);
        final followupDate = _parseDate(journeyFields['followup_date']);

        final procedure =
            journeyFields['procedure_name']?.toString().trim() ?? '';

        add(
          procedureDate,
          'milestone',
          'Procedure date',
          procedure.isNotEmpty
              ? 'Recorded procedure: $procedure.'
              : 'Procedure date recorded in your tracking entry.',
        );

        add(
          followupDate,
          'appointment',
          'Clinician follow-up',
          'Follow the date and instructions advised by your clinician.',
        );

        final recovery =
            journeyFields['recovery_notes']?.toString().trim() ?? '';

        if (entryDate != null && recovery.isNotEmpty) {
          add(
            entryDate,
            'recovery',
            'Recovery progress recorded',
            recovery,
          );
        }
      }

      // General saved-entry marker
      if (entryDate != null) {
        add(
          entryDate,
          'entry',
          'Health entry recorded',
          'You saved a health tracking entry on this date.',
        );
      }
    }

    result.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return result;
  }

  List<Map<String, dynamic>> _eventsFor(DateTime date) => _events
      .where((event) => _sameDay(event['date'] as DateTime, date))
      .toList();

  Map<String, String> _babyInfo(int week) {
    final keys = _babyWeeks.keys.toList()..sort();
    int chosen = keys.first;
    for (final key in keys) {
      if (key <= week) chosen = key;
    }
    return _babyWeeks[chosen]!;
  }

  Widget _pregnancyCard() {
    final week = _pregnancyWeek;

    if (week == null) {
      return _infoCard(
        'Pregnancy dates needed',
        'Add a valid estimated due date, or your pregnancy week during setup, to calculate your pregnancy progress.',
        Icons.pregnant_woman_rounded,
      );
    }

    final info = _babyInfo(week.clamp(8, 40));
    final day = _pregnancyDay ?? 0;
    final dayLabel = day == 0
        ? 'Exactly $week completed weeks'
        : '$day day${day == 1 ? '' : 's'} into week $week';

    final trimester = week < 14
        ? '1st trimester'
        : week < 28
            ? '2nd trimester'
            : '3rd trimester';

    final due = _pregnancyDueDate;
    final daysLeft = due?.difference(DateTime.now()).inDays;
    final progress = (week / 40).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DA.blush, DA.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DA.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PREGNANCY JOURNEY',
            style: DA.body(
              11,
              color: DA.quiet,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$week weeks',
                      style: DA.heading(34, color: DA.rose),
                    ),
                    Text(
                      dayLabel,
                      style: DA.body(14, color: DA.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DA.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DA.border),
                ),
                child: Text(
                  trimester,
                  style: DA.body(
                    12,
                    color: DA.sage,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregnancy progress',
                style: DA.body(13, weight: FontWeight.w700),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: DA.body(
                  13,
                  color: DA.rose,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: DA.border,
              color: DA.rose,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Based on a 40-week pregnancy reference',
            style: DA.body(11, color: DA.quiet),
          ),
          if (due != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DA.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: DA.rose,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated due date',
                          style: DA.body(12, color: DA.quiet),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _prettyDate(due),
                          style: DA.body(
                            15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          daysLeft != null && daysLeft >= 0
                              ? '$daysLeft days remaining'
                              : 'Estimated due date has passed',
                          style: DA.body(12, color: DA.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Divider(color: DA.border, height: 1),
          const SizedBox(height: 18),
          Text(
            'Your baby this week',
            style: DA.heading(18, color: DA.sage),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _babyStat(
                  Icons.straighten_rounded,
                  'Estimated length',
                  info['size']!,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _babyStat(
                  Icons.monitor_weight_outlined,
                  'Estimated weight',
                  info['weight']!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DA.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIZE COMPARISON',
                  style: DA.body(
                    10,
                    color: DA.quiet,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'About the size of a ${info['comparison']}',
                  style: DA.body(
                    15,
                    color: DA.sage,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Weekly development',
            style: DA.body(14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            info['development']!,
            style: DA.body(13, color: DA.muted),
          ),
          const SizedBox(height: 14),
          Text(
            "These are illustrative weekly averages, not measurements of your baby. Individual growth varies. Your antenatal team and scans assess your baby's growth.",
            style: DA.body(11, color: DA.quiet),
          ),
        ],
      ),
    );
  }

  Widget _babyStat(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DA.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: DA.rose),
          const SizedBox(height: 9),
          Text(
            label,
            style: DA.body(11, color: DA.quiet),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DA.body(
              15,
              color: DA.sage,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyProgressCard() {
    switch (_journeyType) {
      case 'pregnancy_care':
        return _pregnancyCard();

      case 'menstrual_health':
        final last = _lastPeriodDate;
        final cycle = _cycleLength;
        final next = last != null && cycle != null
            ? last.add(Duration(days: cycle))
            : null;
        final ovulation = next?.subtract(const Duration(days: 14));
        return _infoCard(
          'Your cycle overview',
          next == null
              ? 'Add your last period date and average cycle length to see estimated cycle dates.'
              : 'Next period estimate: ${_prettyDate(next)}\nEstimated ovulation: ${_prettyDate(ovulation!)}\nCycle length: $cycle days',
          Icons.calendar_month_rounded,
          footer:
              'Cycle and fertile-window dates are estimates, not contraception.',
        );

      case 'postpartum_recovery':
        final days = _postpartumDays;
        return _infoCard(
          'Your recovery journey',
          days == null
              ? 'Your postpartum week will appear when your setup date and weeks postpartum are available.'
              : 'Approximately $days days since your recorded postpartum starting point.\nWeek ${_postpartumWeek ?? 0} of recovery.',
          Icons.spa_outlined,
          footer: 'Recovery varies. Follow your healthcare professional'
              's advice.',
        );

      case 'general_health':
        final count = _entriesThisMonth;
        final target = 20;
        return _infoCard(
          'Your wellness progress',
          '$count tracking entries this month.\n${target - count > 0 ? '${target - count} more entries to reach your personal 20-entry activity target.' : 'You have reached your 20-entry activity target.'}',
          Icons.insights_rounded,
          footer:
              'This is an activity-tracking target, not a medical health score.',
        );

      case 'cosmetic_gynecology':
        return _infoCard(
          'Your procedure recovery',
          'Use your tracking entries to record your procedure date, clinician instructions, medication notes and follow-up dates.',
          Icons.health_and_safety_outlined,
          footer:
              'Recovery timelines and aftercare must come from your treating clinician.',
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _infoCard(String title, String detail, IconData icon,
      {String? footer}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DA.card(color: DA.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DA.rose, size: 27),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title, style: DA.heading(19, color: DA.sage))),
            ],
          ),
          const SizedBox(height: 12),
          Text(detail, style: DA.body(14)),
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(footer, style: DA.body(11, color: DA.quiet)),
          ],
        ],
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'logged_period':
        return DA.rose;
      case 'period':
        return Colors.pink.shade100;
      case 'fertile':
        return Colors.teal.shade300;
      case 'ovulation':
        return Colors.deepPurple.shade400;
      case 'entry':
        return DA.sage;
      case 'wellness':
        return Colors.green.shade500;
      case 'recovery':
        return Colors.teal.shade600;
      case 'recovery_milestone':
        return Colors.cyan.shade600;
      case 'milestone':
        return Colors.orange.shade500;
      case 'appointment':
        return Colors.blue.shade500;
      case 'reminder':
        return Colors.amber.shade700;
      default:
        return DA.muted;
    }
  }

  Widget _calendar() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final offset = first.weekday % 7;
    final start = first.subtract(Duration(days: offset));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DA.card(color: DA.surface),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _prettyMonth(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: DA.heading(18),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(day, style: const TextStyle(fontSize: 11)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 3,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final date = start.add(Duration(days: index));
              final events = _eventsFor(date);
              final selected = _sameDay(date, _selectedDate);
              final today = _sameDay(date, DateTime.now());
              final inMonth = date.month == _visibleMonth.month;

              final primaryEvent = events.firstWhere(
                (event) => event['type'] == 'logged_period',
                orElse: () =>
                    events.isNotEmpty ? events.first : <String, dynamic>{},
              );

              final color = primaryEvent.isEmpty
                  ? (events.isEmpty
                      ? Colors.transparent
                      : _eventColor(events.first['type'] as String))
                  : _eventColor('logged_period');

              final markerTypes = <String>{};
              for (final event in events) {
                markerTypes.add(event['type'] as String);
              }

              final markerColors =
                  markerTypes.take(3).map(_eventColor).toList();

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? DA.rose : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: Colors.white, width: 1.5)
                        : today
                            ? Border.all(color: DA.rose, width: 1.5)
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (today)
                        Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: selected ? Colors.white : DA.rose,
                          ),
                        ),
                      if (today) const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected
                              ? Colors.white
                              : inMonth
                                  ? DA.muted
                                  : DA.quiet.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (markerColors.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: markerColors.map((markerColor) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : markerColor,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legend('Entry', 'entry'),
              if (_journeyType == 'menstrual_health') ...[
                _legend('Logged period', 'logged_period'),
                _legend('Period estimate', 'period'),
                _legend('Fertile window', 'fertile'),
                _legend('Ovulation', 'ovulation'),
              ],
              if (_journeyType == 'pregnancy_care') ...[
                _legend('Milestone', 'milestone'),
                _legend('Appointment', 'appointment'),
              ],
              if (_journeyType == 'postpartum_recovery') ...[
                _legend('Recovery', 'recovery'),
                _legend('Recovery week', 'recovery_milestone'),
                _legend('Follow-up', 'appointment'),
              ],
              if (_journeyType == 'general_health')
                _legend('Wellness', 'wellness'),
              if (_journeyType == 'cosmetic_gynecology') ...[
                _legend('Procedure', 'milestone'),
                _legend('Recovery', 'recovery'),
                _legend('Follow-up', 'appointment'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _prettyMonth(DateTime date) {
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
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _legend(String label, String type) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _eventColor(type),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: DA.body(10, color: DA.quiet)),
      ],
    );
  }

  Widget _selectedDayPanel() {
    final events = _eventsFor(_selectedDate);
    final entries = _entriesForSelectedDay;

    final pregnancyDays = _journeyType == 'pregnancy_care'
        ? _pregnancyDaysOn(_selectedDate)
        : null;

    final pregnancyWeek = _journeyType == 'pregnancy_care'
        ? _pregnancyWeekOn(_selectedDate)
        : null;

    final pregnancyDay = _journeyType == 'pregnancy_care'
        ? _pregnancyDayOn(_selectedDate)
        : null;

    final babyInfo =
        pregnancyWeek != null && pregnancyWeek >= 8 && pregnancyWeek <= 40
            ? _babyInfo(pregnancyWeek)
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DA.card(color: DA.blush),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prettyDate(_selectedDate),
            style: DA.heading(18, color: DA.rose),
          ),
          const SizedBox(height: 12),
          if (_journeyType == 'pregnancy_care') ...[
            if (pregnancyDays == null)
              Text(
                'Pregnancy had not started on this date.',
                style: DA.body(13, color: DA.quiet),
              )
            else if (pregnancyDays > 294)
              Text(
                'This date is beyond the 42-week pregnancy reference. Please follow your antenatal team'
                's guidance.',
                style: DA.body(13, color: DA.quiet),
              )
            else ...[
              Text(
                'Your pregnancy progress',
                style: DA.heading(16, color: DA.sage),
              ),
              const SizedBox(height: 5),
              Text(
                pregnancyDay == 0
                    ? '$pregnancyWeek weeks'
                    : '$pregnancyWeek weeks and $pregnancyDay day${pregnancyDay == 1 ? '' : 's'}',
                style: DA.heading(21, color: DA.rose),
              ),
              const SizedBox(height: 5),
              if (babyInfo != null) ...[
                Text(
                  'Your baby this week',
                  style: DA.body(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Approximate size: ${babyInfo['size']} | ${babyInfo['weight']}',
                  style: DA.body(13),
                ),
                Text(
                  'About the size of a ${babyInfo['comparison']}.',
                  style: DA.body(12, color: DA.muted),
                ),
                const SizedBox(height: 5),
                Text(
                  babyInfo['development']!,
                  style: DA.body(13, color: DA.muted),
                ),
              ] else
                Text(
                  'Your pregnancy progress is calculated from your saved pregnancy dates.',
                  style: DA.body(12, color: DA.muted),
                ),
              const SizedBox(height: 5),
              Text(
                'Pregnancy development information is an estimate, not a medical assessment.',
                style: DA.body(11, color: DA.quiet),
              ),
            ],
            const Divider(height: 24),
          ],
          if (events.isEmpty &&
              entries.isEmpty &&
              _journeyType != 'pregnancy_care')
            Text(
              'No predictions or entries for this date yet.',
              style: DA.body(13, color: DA.quiet),
            ),
          ...events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 9,
                      color: _eventColor(event['type']),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'],
                            style: DA.body(
                              13,
                              weight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            event['detail'],
                            style: DA.body(12, color: DA.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (entries.isNotEmpty)
            Text(
              '${entries.length} health entr${entries.length == 1 ? 'y' : 'ies'} recorded.',
              style: DA.body(13, weight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _upcomingEvents() {
    final today = DateTime.now();
    final upcoming = _events.where((event) {
      final date = event['date'] as DateTime;
      return !date.isBefore(DateTime(today.year, today.month, today.day));
    }).toList()
      ..sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final visible = <Map<String, dynamic>>[];

    if (_journeyType == 'menstrual_health') {
      final seenTypes = <String>{};

      for (final event in upcoming) {
        final type = event['type']?.toString() ?? '';

        if (seenTypes.add(type)) {
          visible.add(event);
        }

        if (visible.length == 4) break;
      }
    } else {
      visible.addAll(upcoming.take(4));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DA.card(color: DA.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming events', style: DA.heading(18, color: DA.sage)),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Text('No upcoming events calculated yet.',
                style: DA.body(13, color: DA.quiet)),
          ...visible.map((event) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.event_note_rounded,
                    color: _eventColor(event['type'])),
                title: Text(event['title'],
                    style: DA.body(13, weight: FontWeight.w700)),
                subtitle: Text(
                  '${_prettyDate(event['date'] as DateTime)} | ${event['detail']}',
                  style: DA.body(11, color: DA.quiet),
                ),
              )),
        ],
      ),
    );
  }

  Widget _journeyInputFields() {
    if (_journeyType == 'menstrual_health') {
      return const SizedBox.shrink();
    }

    final fields = _journeyFields;
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeading(
          '$_journeyName tracking',
          subtitle: 'Add information relevant to your active journey.',
        ),
        ...fields.map((field) {
          final key = field['key']!;
          final multiline = key.contains('notes') ||
              key.contains('instructions') ||
              key.contains('recovery');
          final isDate = key.toLowerCase().contains('date');

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DA.label(field['label']!),
                const SizedBox(height: 7),
                TextField(
                  controller: _controllerFor(key),
                  readOnly: isDate,
                  minLines: multiline ? 2 : 1,
                  maxLines: isDate ? 1 : (multiline ? 4 : 1),
                  onTap: isDate
                      ? () async {
                          final current = _parseDate(
                            _controllerFor(key).text,
                          );
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: current ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            _controllerFor(key).text = _dateString(picked);
                          }
                        }
                      : null,
                  decoration: DA
                      .input(
                        hint: isDate ? 'Select a date' : field['hint']!,
                      )
                      .copyWith(
                        suffixIcon: isDate
                            ? const Icon(Icons.calendar_month_outlined)
                            : null,
                      ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _saveEntry() async {
    final journeyId = int.tryParse(_journey?['id']?.toString() ?? '');
    if (journeyId == null) {
      _showMessage('No active health journey was found.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      // Prevent an entry being saved to a different journey after a switch.
      final currentJourney = await AuthService.getHealthJourney();
      final currentId = int.tryParse(currentJourney?['id']?.toString() ?? '');
      if (currentId != journeyId) {
        await _loadTrackingData();
        throw Exception(
            'Your active journey changed. Please review the refreshed screen before saving.');
      }

      final journeyData = <String, dynamic>{};
      for (final field in _journeyFields) {
        final value = _controllerFor(field['key']!).text.trim();
        if (value.isNotEmpty) journeyData[field['key']!] = value;
      }

      final journal = journalController.text.trim();
      if (_mood == null &&
          _painLevel == null &&
          _selectedSymptoms.isEmpty &&
          journal.isEmpty &&
          journeyData.isEmpty) {
        throw Exception('Add at least one health detail before saving.');
      }

      await AuthService.saveHealthTrackingEntry(
        entryDate: _dateString(_selectedDate),
        painLevel: _painLevel,
        mood: _mood,
        data: {
          'symptoms': _selectedSymptoms.toList(),
          'journal': journal,
          'journey_type': _journeyType,
          'journey_fields': journeyData,
        },
      );

      journalController.clear();
      for (final controller in _fieldControllers.values) {
        controller.clear();
      }
      _mood = null;
      _painLevel = null;
      _selectedSymptoms.clear();

      await _loadTrackingData();
      if (!mounted) return;
      _showMessage('Health entry saved successfully.');
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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

  Widget _buildSectionHeading(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DA.heading(18, color: DA.sage)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: DA.body(12, color: DA.quiet)),
          ],
        ],
      ),
    );
  }

  Widget _choiceSection(
    String title,
    List<String> options,
    String? selected,
    ValueChanged<String?> onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() => onSelected(value ? option : null));
              },
              selectedColor: DA.blush,
              backgroundColor: DA.surface,
              labelStyle: DA.body(
                13,
                color: isSelected ? DA.rose : DA.muted,
                weight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? DA.rose : DA.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _symptomSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          'Symptoms and experiences',
          subtitle: 'Select anything you experienced on this date.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: symptoms.map((symptom) {
            final selected = _selectedSymptoms.contains(symptom);
            return FilterChip(
              label: Text(symptom),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
              selectedColor: DA.blush,
              backgroundColor: DA.surface,
              labelStyle: DA.body(
                12,
                color: selected ? DA.rose : DA.muted,
              ),
              side: BorderSide(
                color: selected ? DA.rose : DA.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _journalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          'Journal',
          subtitle: 'Add anything else you would like to remember.',
        ),
        TextField(
          controller: journalController,
          minLines: 3,
          maxLines: 6,
          decoration: DA.input(
            hint: 'Write your notes here...',
          ),
        ),
      ],
    );
  }

  Widget _entryCard(dynamic entry) {
    if (entry is! Map) return const SizedBox.shrink();

    final date = _parseDate(entry['entry_date']);
    final mood = entry['mood']?.toString();
    final pain = entry['pain_level']?.toString();

    final rawData = entry['data'];
    final data = rawData is Map ? rawData : <String, dynamic>{};

    final rawSymptoms = data['symptoms'];
    final savedSymptoms = rawSymptoms is List
        ? rawSymptoms.map((item) => item.toString()).toList()
        : <String>[];

    final journal = data['journal']?.toString() ?? '';

    final rawFields = data['journey_fields'];
    final fields = rawFields is Map ? rawFields : <String, dynamic>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: DA.card(color: DA.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: DA.rose),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date == null ? 'Health entry' : _prettyDate(date),
                  style: DA.body(14, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (mood != null && mood.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Mood: $mood', style: DA.body(13)),
          ],
          if (pain != null && pain.isNotEmpty)
            Text('Pain level: $pain', style: DA.body(13)),
          if (savedSymptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Symptoms: ${savedSymptoms.join(', ')}',
              style: DA.body(13),
            ),
          ],
          ...fields.entries.where((item) {
            return item.value != null &&
                item.value.toString().trim().isNotEmpty;
          }).map((item) {
            final label = item.key
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) => word.isEmpty
                    ? word
                    : '${word[0].toUpperCase()}${word.substring(1)}')
                .join(' ');

            return Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                '$label: ${item.value}',
                style: DA.body(13),
              ),
            );
          }),
          if (journal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Journal: $journal', style: DA.body(13)),
          ],
        ],
      ),
    );
  }

  Widget _menstrualPeriodLogger() {
    if (_journeyType != 'menstrual_health') {
      return const SizedBox.shrink();
    }

    final selectedStartDate = _periodLogStartDate ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: DA.card(color: DA.blush),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeading(
            'Has your period started?',
            subtitle:
                'Log the first day of your period. Her Health will calculate the expected period days and update your cycle calendar automatically.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DA.label('Period start date'),
                    const SizedBox(height: 5),
                    Text(
                      _prettyDate(selectedStartDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final today = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(
                            today.year,
                            today.month,
                            today.day,
                          ),
                        );

                        if (picked != null && mounted) {
                          setState(() {
                            _periodLogStartDate = picked;
                          });
                        }
                      },
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Change date'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _hasKnownPeriodLength
                ? 'Your saved average period duration is $_periodLength days. '
                    'We will use this to estimate the remaining period days. '
                    'You do not need to enter an end date.'
                : 'You have not provided your average period duration. '
                    'For now, we will use a five-day estimate to calculate '
                    'the remaining period days. You can update your average '
                    'when you know it. You do not need to enter an end date.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          DA.label('Menstrual flow'),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: _periodFlow,
            decoration: DA.input(hint: 'Select flow'),
            items: ['Light', 'Moderate', 'Heavy']
                .map((flow) => DropdownMenuItem(
                      value: flow,
                      child: Text(flow),
                    ))
                .toList(),
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _periodFlow = value);
                    }
                  },
          ),
          const SizedBox(height: 14),
          DA.label('Period notes (optional)'),
          const SizedBox(height: 7),
          TextField(
            controller: _controllerFor('menstrual_period_notes'),
            minLines: 2,
            maxLines: 4,
            decoration: DA.input(
              hint: 'Any symptoms, changes or notes about this period...',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _savePeriodLog,
              icon: const Icon(Icons.water_drop_outlined),
              label: const Text('Log period started'),
              style: DA.primary(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePeriodLog() async {
    final selectedDate = _periodLogStartDate ?? DateTime.now();
    final startDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (startDate.isAfter(todayDate)) {
      _showMessage(
        'A period start date cannot be in the future.',
        isError: true,
      );
      return;
    }

    final journeyId = int.tryParse(_journey?['id']?.toString() ?? '');

    if (journeyId == null) {
      _showMessage('No active health journey was found.', isError: true);
      return;
    }

    // Prevent duplicate period-start records for the same date.
    for (final entry in _entries) {
      if (entry is! Map) continue;

      final data = entry['data'];
      if (data is! Map) continue;

      DateTime? existingStart;
      final existingLog = data['menstrual_log'];

      if (existingLog is Map) {
        existingStart = _parseDate(existingLog['start_date']);
      } else {
        final fields = data['journey_fields'];
        if (fields is Map) {
          existingStart = _parseDate(fields['period_start_date']);
        }
      }

      if (existingStart != null && _sameDay(existingStart, startDate)) {
        _showMessage(
          'A period has already been logged for this start date.',
          isError: true,
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final currentJourney = await AuthService.getHealthJourney();
      final currentId = int.tryParse(
        currentJourney?['id']?.toString() ?? '',
      );

      if (currentId != journeyId) {
        await _loadTrackingData();
        throw Exception(
          'Your active journey changed. Please review the refreshed screen before saving.',
        );
      }

      await AuthService.saveHealthTrackingEntry(
        entryDate: _dateString(startDate),
        data: {
          'journey_type': 'menstrual_health',
          'menstrual_log': {
            'start_date': _dateString(startDate),
            'period_length': _periodLength,
            'period_length_is_estimate': !_hasKnownPeriodLength,
            'flow': _periodFlow,
            'notes': _controllerFor('menstrual_period_notes').text.trim(),
          },
        },
      );

      _periodLogStartDate = null;
      _periodFlow = 'Moderate';
      _controllerFor('menstrual_period_notes').clear();

      await _loadTrackingData();

      if (!mounted) return;

      _showMessage(
        'Period start saved. Your cycle calendar has been updated.',
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _trackingForm() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: DA.card(color: DA.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _menstrualPeriodLogger(),
          _buildSectionHeading(
            'Daily health check-in',
            subtitle:
                'Record how you are feeling on ${_prettyDate(_selectedDate)}.',
          ),
          _choiceSection(
            'How is your mood?',
            moods,
            _mood,
            (value) => _mood = value,
          ),
          const SizedBox(height: 18),
          _choiceSection(
            'Pain level',
            painLevels,
            _painLevel,
            (value) => _painLevel = value,
          ),
          const SizedBox(height: 18),
          _symptomSelector(),
          const SizedBox(height: 18),
          _journeyInputFields(),
          const SizedBox(height: 10),
          _journalField(),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveEntry,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save health entry'),
              style: DA.primary(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statisticsCard() {
    return Row(
      children: [
        Expanded(
          child: _statItem(
            'Entries this month',
            '$_entriesThisMonth',
            Icons.calendar_month_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statItem(
            'Most common mood',
            _mostCommonMood,
            Icons.mood_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DA.card(color: DA.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DA.rose, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: DA.heading(16, color: DA.sage),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: DA.body(11, color: DA.quiet)),
        ],
      ),
    );
  }

  Widget _historySection() {
    final entries = _entries.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          'Your tracking history',
          subtitle: 'Your saved entries for this health journey.',
        ),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: DA.card(color: DA.surface),
            child: Column(
              children: [
                Icon(Icons.notes_rounded, size: 34, color: DA.quiet),
                const SizedBox(height: 8),
                Text(
                  'No entries yet',
                  style: DA.body(14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your saved health entries will appear here.',
                  textAlign: TextAlign.center,
                  style: DA.body(12, color: DA.quiet),
                ),
              ],
            ),
          )
        else
          ...entries.map(_entryCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      appBar: AppBar(
        title: const Text('Health Tracking'),
        backgroundColor: DA.ground,
        foregroundColor: DA.sage,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadTrackingData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _journey == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 54,
                          color: DA.rose,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No active health journey',
                          style: DA.heading(20, color: DA.sage),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set up a health journey from your Health Profile to start tracking.',
                          style: DA.body(14, color: DA.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _loadTrackingData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: DA.primary(),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTrackingData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: DA.card(color: DA.blush),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _journeyName,
                              style: DA.heading(21, color: DA.sage),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _journeyDescription,
                              style: DA.body(13, color: DA.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _journeyProgressCard(),
                      const SizedBox(height: 16),
                      _statisticsCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeading(
                        'Your health calendar',
                        subtitle:
                            'Select a date to view its events and entries.',
                      ),
                      _calendar(),
                      const SizedBox(height: 12),
                      _selectedDayPanel(),
                      const SizedBox(height: 18),
                      _upcomingEvents(),
                      const SizedBox(height: 20),
                      _trackingForm(),
                      const SizedBox(height: 20),
                      _historySection(),
                    ],
                  ),
                ),
    );
  }
}
