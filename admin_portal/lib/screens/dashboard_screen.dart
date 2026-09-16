import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'patients_screen.dart';
import 'appointments_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'nia_chat_screen.dart';
import 'book_appointment_screen.dart';
import 'staff_management_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String name;

  const DashboardScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.action,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NiaChatScreen()));
        },
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                          },
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(name: name)));
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Text(_getInitials(name),style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Good Morning, $name!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Super Admin', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview stat cards
                    Row(
                      children: [
                        _statCard('Patients Today', '18'),
                        const SizedBox(width: 12),
                        _statCard('Appointments', '21'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statCard('New Patients', '5'),
                        const SizedBox(width: 12),
                        _statCard('Cancelled', '3'),
                      ],
                    ),
                    const SizedBox(height: 28),

                    const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _quickActionCard(context, Icons.person_add, 'Register\nPatient', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientsScreen()));
                        }),
                        const SizedBox(width: 12),
                        _quickActionCard(context, Icons.calendar_month, 'Book\nAppointment', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BookAppointmentScreen()));
                        }),
                        const SizedBox(width: 12),
                        _quickActionCard(context, Icons.people, 'Staff\nManagement', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const StaffManagementScreen()));
                        }),
                        const SizedBox(width: 12),
                        _quickActionCard(context, Icons.bar_chart, 'Reports', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 28),

                    const Text('Today\'s Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          _scheduleRow('08:00', 'Sarah Mokoena'),
                          const Divider(height: 1),
                          _scheduleRow('09:30', 'Thando Khumalo'),
                          const Divider(height: 1),
                          _scheduleRow('11:00', 'Lerato Dube'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _bottomNavItem(context, Icons.people, 'Patients', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientsScreen()));
                        }),
                        _bottomNavItem(context, Icons.calendar_month, 'Appointments', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentsScreen()));
                        }),
                        _bottomNavItem(context, Icons.bar_chart, 'Reports', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                        }),
                        _bottomNavItem(context, Icons.settings, 'Settings', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.action)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scheduleRow(String time, String patientName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(patientName),
        ],
      ),
    );
  }

  Widget _bottomNavItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}