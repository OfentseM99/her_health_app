import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;

      final token = await ApiService.getToken();
      final roleId = await ApiService.getRoleId();
      final isLoggedIn = token != null &&
          roleId != null &&
          ApiService.staffRoleIds.contains(roleId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isLoggedIn ? const DashboardScreen() : const WelcomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.spa,
                  size: 120,
                  color: Colors.pink.shade200,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Women\'s Health Companion',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inspired by Dr. Mbokota\'s practice.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                const Text(
                  'Admin Portal',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Loading...',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 40),
                const Text(
                  'version 1.0',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}