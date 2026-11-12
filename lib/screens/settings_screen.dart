import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme_manager.dart';
import 'information_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hydrationReminder = true;
  bool _periodReminder = true;
  bool _appointmentReminder = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _hydrationReminder =
          preferences.getBool('hydration_reminder') ?? true;
      _periodReminder =
          preferences.getBool('period_reminder') ?? true;
      _appointmentReminder =
          preferences.getBool('appointment_reminder') ?? true;
      _loading = false;
    });
  }

  Future<void> _saveReminder(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  Future<void> _changeTheme(ThemeMode? mode) async {
    if (mode == null) return;
    await ThemeManager.instance.setThemeMode(mode);
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionTitle('Appearance'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose how Her Health should look.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ThemeMode>(
                          value: ThemeManager.instance.themeMode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: ThemeMode.values.map((mode) {
                            return DropdownMenuItem<ThemeMode>(
                              value: mode,
                              child: Text(_themeLabel(mode)),
                            );
                          }).toList(),
                          onChanged: _changeTheme,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Reminders'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.water_drop_outlined),
                        title: const Text('Hydration reminders'),
                        subtitle: const Text(
                          'Reminders to drink water.',
                        ),
                        value: _hydrationReminder,
                        onChanged: (value) {
                          setState(() => _hydrationReminder = value);
                          _saveReminder('hydration_reminder', value);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Period reminders'),
                        subtitle: const Text(
                          'Reminders related to your cycle.',
                        ),
                        value: _periodReminder,
                        onChanged: (value) {
                          setState(() => _periodReminder = value);
                          _saveReminder('period_reminder', value);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.event_available_outlined),
                        title: const Text('Appointment reminders'),
                        subtitle: const Text(
                          'Reminders about upcoming appointments.',
                        ),
                        value: _appointmentReminder,
                        onChanged: (value) {
                          setState(() => _appointmentReminder = value);
                          _saveReminder('appointment_reminder', value);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Privacy & Security'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Privacy and data protection'),
                    subtitle: const Text(
                      'Learn how your information is handled.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Privacy & Security'),
                          content: const Text(
                            'Her Health is designed to protect your '
                            'personal health information. Always keep '
                            'your account details private and sign out '
                            'when using a shared device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Account'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Personal Information'),
                    subtitle: const Text(
                      'View and update your profile.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Support'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Her Health'),
                    subtitle: const Text('App information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const InformationScreen(),
  ),
);
                    },
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Your preferences are saved on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white60
                        : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

