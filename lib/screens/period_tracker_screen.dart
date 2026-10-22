import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  // Her Health colour palette
  static const Color rose = Color(0xFFB04F6C);
  static const Color lightRose = Color(0xFFD9879E);
  static const Color blushPink = Color(0xFFF6DCE2);
  static const Color sage = Color(0xFF6E7B5F);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);
  static const Color pageBackground = Color(0xFFFAF6F3);

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  DateTime lastPeriodStart = DateTime.now();

  int cycleLength = 28;
  int periodLength = 5;
  bool isLoading = true;

  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedMood = 'Okay';

  Map<String, Map<String, String>> journalEntries = {};

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  @override
  void dispose() {
    symptomsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String monthName(int month) {
    const months = [
      '',
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

    return months[month];
  }

  String formattedDate(DateTime date) =>
      '${date.day} ${monthName(date.month)} ${date.year}';

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedPeriod = prefs.getString('health_last_period');
    final savedCycleLength = prefs.getInt('health_cycle_length');
    final savedPeriodLength = prefs.getInt('health_period_length');
    final savedJournal = prefs.getString('health_journal_entries');

    if (!mounted) return;

    setState(() {
      if (savedPeriod != null) {
        lastPeriodStart = DateTime.tryParse(savedPeriod) ?? DateTime.now();
      }

      cycleLength = savedCycleLength ?? 28;
      periodLength = savedPeriodLength ?? 5;

      if (savedJournal != null) {
        try {
          final decoded = jsonDecode(savedJournal) as Map<String, dynamic>;

          journalEntries = decoded.map((key, value) {
            final entry = Map<String, dynamic>.from(value as Map);

            return MapEntry(
              key,
              entry.map((k, v) => MapEntry(k, v.toString())),
            );
          });
        } catch (_) {
          journalEntries = {};
        }
      }

      isLoading = false;
    });

    loadJournalForDate(selectedDay);
  }

  Future<void> savePeriodSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('health_last_period', dateKey(lastPeriodStart));
    await prefs.setInt('health_cycle_length', cycleLength);
    await prefs.setInt('health_period_length', periodLength);
  }

  Future<void> saveJournal() async {
    final symptoms = symptomsController.text.trim();
    final notes = notesController.text.trim();

    if (symptoms.isEmpty && notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter symptoms or notes first.'),
        ),
      );
      return;
    }

    setState(() {
      journalEntries[dateKey(selectedDay)] = {
        'symptoms': symptoms,
        'notes': notes,
        'mood': selectedMood,
      };
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'health_journal_entries',
      jsonEncode(journalEntries),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal entry saved.')),
    );
  }

  Future<void> deleteJournalEntry() async {
    journalEntries.remove(dateKey(selectedDay));

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'health_journal_entries',
      jsonEncode(journalEntries),
    );

    loadJournalForDate(selectedDay);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal entry deleted.')),
    );
  }

  void loadJournalForDate(DateTime date) {
    final entry = journalEntries[dateKey(date)];

    symptomsController.text = entry?['symptoms'] ?? '';
    notesController.text = entry?['notes'] ?? '';
    selectedMood = entry?['mood'] ?? 'Okay';

    if (mounted) setState(() {});
  }

  // Cycle calculations

  bool isPeriodDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final start = DateTime(
      lastPeriodStart.year,
      lastPeriodStart.month,
      lastPeriodStart.day,
    );

    final difference = date.difference(start).inDays;

    return difference >= 0 && difference < periodLength;
  }

  DateTime get nextPeriodDate =>
      lastPeriodStart.add(Duration(days: cycleLength));

  DateTime get ovulationDate =>
      lastPeriodStart.add(Duration(days: cycleLength - 14));

  bool isPredictedPeriodDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final nextStart = DateTime(
      nextPeriodDate.year,
      nextPeriodDate.month,
      nextPeriodDate.day,
    );

    final difference = date.difference(nextStart).inDays;

    return difference >= 0 && difference < periodLength;
  }

  bool isOvulationDay(DateTime day) => isSameDate(day, ovulationDate);

  bool isFertileDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final ovulation = DateTime(
      ovulationDate.year,
      ovulationDate.month,
      ovulationDate.day,
    );

    final difference = date.difference(ovulation).inDays;

    return difference >= -5 && difference <= 1;
  }

  void selectCalendarDate(DateTime selected, DateTime focused) {
    setState(() {
      selectedDay = selected;
      focusedDay = focused;
    });

    loadJournalForDate(selected);
  }

  Future<void> logPeriod() async {
    final date = await showDatePicker(
      context: context,
      initialDate: lastPeriodStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select the first day of your period',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: rose,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: forestGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    setState(() {
      lastPeriodStart = date;
      focusedDay = date;
      selectedDay = date;
    });

    await savePeriodSettings();

    if (!mounted) return;

    loadJournalForDate(date);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Period start date saved.')),
    );
  }

  // Reusable card

  Widget card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: forestGreen.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: forestGreen,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: warmText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget legendItem(Color color, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: warmText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: warmText,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: forestGreen,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: forestGreen,
        ),
      ),
    );
  }

  InputDecoration fieldDecoration({
    required String hint,
    IconData? icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFAAA19D),
        fontSize: 13,
      ),
      prefixIcon: icon == null ? null : Icon(icon, color: sage, size: 20),
      filled: true,
      fillColor: pageBackground,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: rose, width: 1.5),
      ),
    );
  }

  // Calendar tab

  Widget buildCalendarTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Next period summary
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [rose, lightRose],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: rose.withValues(alpha: 0.20),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated next period',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate(nextPeriodDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cycleLength-day cycle',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calendar
        card(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: blushPink,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: rose,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle calendar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: forestGreen,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Select a date to view your journal',
                          style: TextStyle(
                            fontSize: 12,
                            color: warmText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2035),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDate(day, selectedDay),
                onDaySelected: selectCalendarDate,
                calendarFormat: CalendarFormat.month,
                rowHeight: 45,
                daysOfWeekHeight: 32,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: forestGreen,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: forestGreen,
                  ),
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: forestGreen,
                    fontSize: 16,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: warmText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  weekendStyle: TextStyle(
                    color: warmText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: sage.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: rose,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(
                    color: forestGreen,
                    fontSize: 13,
                  ),
                  weekendTextStyle: const TextStyle(
                    color: forestGreen,
                    fontSize: 13,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focused) {
                    Color? color;
                    IconData? icon;

                    if (isPeriodDay(day)) {
                      color = rose;
                      icon = Icons.water_drop;
                    } else if (isPredictedPeriodDay(day)) {
                      color = lightRose;
                      icon = Icons.water_drop_outlined;
                    } else if (isOvulationDay(day)) {
                      color = const Color(0xFFC58A42);
                      icon = Icons.favorite;
                    } else if (isFertileDay(day)) {
                      color = sage;
                      icon = Icons.eco_outlined;
                    }

                    if (icon == null) return null;

                    return Center(
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calendar guide
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                'Calendar guide',
                subtitle: 'What the colours on your calendar mean.',
              ),
              legendItem(rose, Icons.water_drop, 'Recorded period'),
              legendItem(
                lightRose,
                Icons.water_drop_outlined,
                'Predicted period',
              ),
              legendItem(
                sage,
                Icons.eco_outlined,
                'Estimated fertile window',
              ),
              legendItem(
                const Color(0xFFC58A42),
                Icons.favorite_outline,
                'Estimated ovulation',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cycle details
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                'Your cycle',
                subtitle: 'Based on the information you have recorded.',
              ),
              summaryRow('Cycle length', '$cycleLength days'),
              summaryRow('Period length', '$periodLength days'),
              summaryRow(
                'Estimated ovulation',
                formattedDate(ovulationDate),
              ),
              summaryRow(
                'Estimated next period',
                formattedDate(nextPeriodDate),
              ),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: blushPink.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: rose,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cycle dates are estimates and may vary. '
                        'Do not use these predictions as contraception '
                        'or as a medical diagnosis.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: warmText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Log period button
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: logPeriod,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              'Log period start date',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: rose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // Journal tab

  Widget buildJournalTab() {
    final entryExists = journalEntries.containsKey(dateKey(selectedDay));

    final dates = journalEntries.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                'Health journal',
                subtitle: 'Record how you feel, symptoms, and health notes.',
              ),

              // Select journal date
              InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDay,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: rose,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: forestGreen,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (date == null || !mounted) return;

                  setState(() {
                    selectedDay = date;
                    focusedDay = date;
                  });

                  loadJournalForDate(date);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: blushPink.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: rose,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Journal date',
                              style: TextStyle(
                                fontSize: 12,
                                color: warmText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formattedDate(selectedDay),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: forestGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: forestGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              fieldLabel('Symptoms'),
              TextField(
                controller: symptomsController,
                textCapitalization: TextCapitalization.sentences,
                decoration: fieldDecoration(
                  hint: 'e.g. cramps, headache, fatigue',
                  icon: Icons.healing_outlined,
                ),
              ),
              const SizedBox(height: 20),

              fieldLabel('How are you feeling?'),
              DropdownButtonFormField<String>(
                initialValue: selectedMood,
                isExpanded: true,
                decoration: fieldDecoration(
                  hint: 'Choose your mood',
                  icon: Icons.mood_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Great',
                    child: Text('Great'),
                  ),
                  DropdownMenuItem(
                    value: 'Good',
                    child: Text('Good'),
                  ),
                  DropdownMenuItem(
                    value: 'Okay',
                    child: Text('Okay'),
                  ),
                  DropdownMenuItem(
                    value: 'Low',
                    child: Text('Low'),
                  ),
                  DropdownMenuItem(
                    value: 'Unwell',
                    child: Text('Unwell'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedMood = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              fieldLabel('Notes'),
              TextField(
                controller: notesController,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: fieldDecoration(
                  hint: 'Write any notes about your health...',
                  icon: Icons.edit_note,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: saveJournal,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text(
                    'Save journal entry',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),

              if (entryExists) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: deleteJournalEntry,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: rose,
                    ),
                    label: const Text(
                      'Delete this entry',
                      style: TextStyle(
                        color: rose,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent journal entries
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                'Recent entries',
                subtitle: 'Select an entry to view or update it.',
              ),
              if (dates.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        color: lightRose,
                        size: 38,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No journal entries yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: forestGreen,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Your saved entries will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: warmText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...dates.take(5).map((date) {
                  final entry = journalEntries[date]!;

                  final symptoms = entry['symptoms'] ?? '';
                  final notes = entry['notes'] ?? '';
                  final mood = entry['mood'] ?? 'Okay';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: pageBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: blushPink,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.menu_book_outlined,
                          color: rose,
                        ),
                      ),
                      title: Text(
                        date,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: forestGreen,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (symptoms.isNotEmpty) symptoms,
                            if (notes.isNotEmpty) notes,
                          ].join('\n').isEmpty
                              ? 'No symptoms or notes'
                              : [
                                  if (symptoms.isNotEmpty) symptoms,
                                  if (notes.isNotEmpty) notes,
                                ].join('\n'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: warmText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: blushPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          mood,
                          style: const TextStyle(
                            color: rose,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      onTap: () {
                        final parsedDate = DateTime.tryParse(date);
                        if (parsedDate == null) return;

                        setState(() {
                          selectedDay = parsedDate;
                          focusedDay = parsedDate;
                        });

                        loadJournalForDate(parsedDate);
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // Insights tab

  Widget buildInsightsTab() {
    final totalEntries = journalEntries.length;
    final symptomCounts = <String, int>{};
    final moodCounts = <String, int>{};

    for (final entry in journalEntries.values) {
      final symptoms = entry['symptoms'] ?? '';

      for (final symptom in symptoms.split(',')) {
        final value = symptom.trim().toLowerCase();

        if (value.isNotEmpty) {
          symptomCounts[value] = (symptomCounts[value] ?? 0) + 1;
        }
      }

      final mood = entry['mood'] ?? '';

      if (mood.isNotEmpty) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    final sortedSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Overview card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: forestGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your health overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'You have saved $totalEntries '
                      '${totalEntries == 1 ? 'journal entry' : 'journal entries'}.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Journal count
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                'Journal activity',
                subtitle: 'A quick look at your recorded health information.',
              ),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: blushPink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: rose,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalEntries',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: rose,
                          ),
                        ),
                        const Text(
                          'Journal entries saved',
                          style: TextStyle(
                            color: warmText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Symptom summary
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                'Frequently recorded symptoms',
                subtitle: 'Symptoms you have entered most often.',
              ),
              if (sortedSymptoms.isEmpty)
                const Text(
                  'Record symptoms in your journal to see summaries here.',
                  style: TextStyle(
                    color: warmText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                )
              else
                ...sortedSymptoms.take(5).map(
                      (item) => summaryRow(
                        item.key[0].toUpperCase() + item.key.substring(1),
                        '${item.value} ${item.value == 1 ? 'entry' : 'entries'}',
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mood summary
        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                'Mood summary',
                subtitle: 'How you have described feeling in your entries.',
              ),
              if (sortedMoods.isEmpty)
                const Text(
                  'Your mood summaries will appear after you save entries.',
                  style: TextStyle(
                    color: warmText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                )
              else
                ...sortedMoods.map(
                  (item) => summaryRow(
                    item.key,
                    '${item.value} ${item.value == 1 ? 'entry' : 'entries'}',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Health disclaimer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: blushPink.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                color: rose,
                size: 23,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These summaries reflect only the information you enter. '
                  'They do not diagnose conditions or replace advice from '
                  'a qualified healthcare professional.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: warmText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Main screen

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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: pageBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/backgrounds/background.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: pageBackground),
            ),
            Container(
              color: pageBackground.withValues(alpha: 0.82),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Screen heading
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Image.asset(
                            'assets/images/logo/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.health_and_safety_outlined,
                              size: 34,
                              color: rose,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health Tracking',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: forestGreen,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Understand your health over time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: warmText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: warmText,
                      indicator: BoxDecoration(
                        color: rose,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(
                          height: 62,
                          icon: Icon(Icons.calendar_month_outlined),
                          text: 'Calendar',
                        ),
                        Tab(
                          height: 62,
                          icon: Icon(Icons.edit_note_outlined),
                          text: 'Journal',
                        ),
                        Tab(
                          height: 62,
                          icon: Icon(Icons.insights_outlined),
                          text: 'Insights',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tab contents
                  Expanded(
                    child: TabBarView(
                      children: [
                        buildCalendarTab(),
                        buildJournalTab(),
                        buildInsightsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
