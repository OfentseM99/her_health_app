import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import '../theme/design_a.dart';

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

      final biometricEnabled = await ApiService.isBiometricUnlockEnabled();
      final token = await ApiService.getToken();
      final roleId = await ApiService.getRoleId();
      final isLoggedIn =
          !biometricEnabled &&
          token != null &&
          roleId != null &&
          ApiService.staffRoleIds.contains(roleId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              // Staff accounts are created by the practice, never from a public
              // page: not logged in -> straight to Log in.
              isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.spa, size: 120, color: DA.rose),
                ),
                const SizedBox(height: 24),
                Text('Her Health', style: DA.heading(36)),
                const SizedBox(height: 6),
                Text(
                  'Admin portal',
                  style: DA.body(17, color: DA.sage, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  "Inspired by Dr. Mbokota's practice.",
                  style: DA.body(15, color: DA.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DA.rose,
                  ),
                ),
                const SizedBox(height: 40),
                Text('Version 1.0', style: DA.body(12, color: DA.quiet)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
