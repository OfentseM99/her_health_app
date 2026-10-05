import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (NOT BLURRED)
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Slight transparent overlay for readability
          Container(
            color: Colors.white.withValues(alpha: 0.25),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo/logo.png',
                  height: 160,
                ),

                const SizedBox(height: 25),

                Text(
                  "Her Health",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sageGreen,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Your wellness journey starts here",
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
