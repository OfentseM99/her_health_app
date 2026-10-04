import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'health_profile_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to use Her Health.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.logout();

    if (!context.mounted) return;

    // Clear every screen behind us so the back button can't return to a
    // logged-in screen.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE89CB0),
        title: const Text(
          "Settings ⚙️",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if ((AuthService.firstName ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    "Signed in as ${AuthService.firstName}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF959B7D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Color(0xFF959B7D)),
                  title: const Text('Health Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade400),
                  title: Text(
                    'Log out',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                  onTap: () => _confirmLogout(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
