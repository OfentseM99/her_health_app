import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color pink = Color(0xFFE89CB0);
  static const Color green = Color(0xFF959B7D);
  static const Color lightPink = Color(0xFFFBECEF);

  // ============================================================
  // CALENDAR
  // ============================================================

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  // ============================================================
  // MENSTRUAL CYCLE SETTINGS
  // ============================================================

  int cycleLength = 28;
  int periodLength = 5;

  // User's last recorded period
  DateTime lastPeriodStart = DateTime.now();

  // ============================================================
  // PERIOD DAYS
  // ============================================================

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isPeriodDay(DateTime day) {
    final difference = day.difference(lastPeriodStart).inDays;

    return difference >= 0 && difference < periodLength;
  }

  // ============================================================
  // PREDICTED PERIOD
  // ============================================================

  bool isPredictedPeriodDay(DateTime day) {
    final nextPeriod = DateTime(
      lastPeriodStart.year,
      lastPeriodStart.month,
      lastPeriodStart.day + cycleLength,
    );

    final difference = day.difference(nextPeriod).inDays;

    return difference >= 0 && difference < periodLength;
  }

  // ============================================================
  // OVULATION
  // ============================================================

  DateTime get ovulationDate {
    return lastPeriodStart.add(
      Duration(days: cycleLength - 14),
    );
  }

  bool isOvulationDay(DateTime day) {
    return isSameDate(day, ovulationDate);
  }

  // ============================================================
  // FERTILE WINDOW
  // ============================================================

  bool isFertileDay(DateTime day) {
    final difference = day.difference(ovulationDate).inDays;

    return difference >= -5 && difference <= 1;
  }

  // ============================================================
  // NEXT PERIOD
  // ============================================================

  DateTime get nextPeriodDate {
    return lastPeriodStart.add(
      Duration(days: cycleLength),
    );
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  void selectDate(DateTime selected, DateTime focused) {
    setState(() {
      selectedDay = selected;
      focusedDay = focused;
    });

    showDateInformation(selected);
  }

  // ============================================================
  // DATE INFORMATION
  // ============================================================

  void showDateInformation(DateTime date) {
    String message;

    if (isPeriodDay(date)) {
      message = "🌸 Period day";
    } else if (isPredictedPeriodDay(date)) {
      message = "🩸 Predicted period";
    } else if (isOvulationDay(date)) {
      message = "🥚 Estimated ovulation day";
    } else if (isFertileDay(date)) {
      message = "💚 Fertile window";
    } else {
      message = "No cycle event predicted for this day.";
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month,
                size: 45,
                color: pink,
              ),
              const SizedBox(height: 15),
              Text(
                "${date.day}/${date.month}/${date.year}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CALENDAR MARKER
  // ============================================================

  Widget calendarMarker(
    DateTime day,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          Container(
            color: Colors.white.withValues(alpha: 0.30),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Image.asset(
                    'assets/images/logo/logo.png',
                    height: 90,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Period Tracker 🌸",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Understand your cycle and know what to expect.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: green,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // NEXT PERIOD CARD
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: pink,
                          size: 45,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Your next period",
                          style: TextStyle(
                            fontSize: 18,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${nextPeriodDate.day} ${monthName(nextPeriodDate.month)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: pink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${cycleLength} day cycle",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // CALENDAR
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2035),
                      focusedDay: focusedDay,
                      selectedDayPredicate: (day) {
                        return selectedDay != null &&
                            isSameDate(day, selectedDay!);
                      },
                      onDaySelected: selectDate,
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: green,
                          fontWeight: FontWeight.bold,
                        ),
                        weekendStyle: TextStyle(
                          color: pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: pink,
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                        defaultTextStyle: const TextStyle(
                          fontSize: 15,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (isPeriodDay(day)) {
                            return calendarMarker(
                              day,
                              pink,
                              Icons.water_drop,
                            );
                          }

                          if (isPredictedPeriodDay(day)) {
                            return calendarMarker(
                              day,
                              Colors.pink.shade200,
                              Icons.water_drop_outlined,
                            );
                          }

                          if (isOvulationDay(day)) {
                            return calendarMarker(
                              day,
                              Colors.orange,
                              Icons.favorite,
                            );
                          }

                          if (isFertileDay(day)) {
                            return calendarMarker(
                              day,
                              Colors.green.shade400,
                              Icons.eco,
                            );
                          }

                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // LEGEND
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cycle information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 15),
                        legendItem(
                          pink,
                          Icons.water_drop,
                          "Period",
                        ),
                        legendItem(
                          Colors.pink.shade200,
                          Icons.water_drop_outlined,
                          "Predicted period",
                        ),
                        legendItem(
                          Colors.green.shade400,
                          Icons.eco,
                          "Fertile window",
                        ),
                        legendItem(
                          Colors.orange,
                          Icons.favorite,
                          "Estimated ovulation",
                        ),
                        legendItem(
                          green,
                          Icons.today,
                          "Today",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // CYCLE SUMMARY
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lightPink,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your cycle",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 15),
                        summaryRow(
                          "Cycle length",
                          "$cycleLength days",
                        ),
                        summaryRow(
                          "Period length",
                          "$periodLength days",
                        ),
                        summaryRow(
                          "Estimated ovulation",
                          "${ovulationDate.day} ${monthName(ovulationDate.month)}",
                        ),
                        summaryRow(
                          "Next period",
                          "${nextPeriodDate.day} ${monthName(nextPeriodDate.month)}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // LOG PERIOD BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: logPeriod,
                      icon: const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Log Period 🌸",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEGEND ITEM
  // ============================================================

  Widget legendItem(
    Color color,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOG PERIOD
  // ============================================================

  void logPeriod() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    ).then((date) {
      if (date == null) return;

      setState(() {
        lastPeriodStart = date;
        focusedDay = date;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Period start date saved 🌸",
          ),
        ),
      );
    });
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String monthName(int month) {
    const months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return months[month];
  }
}
