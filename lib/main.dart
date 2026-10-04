import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chatbot_screen.dart';



void main() {

  runApp(const HerHealthApp());

}



class HerHealthApp extends StatelessWidget {

  const HerHealthApp({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: "Her Health",



      theme: ThemeData(

        primaryColor: const Color(0xFFE89CB0),


        scaffoldBackgroundColor: Colors.white,



        colorScheme: ColorScheme.fromSeed(

          seedColor: const Color(0xFFE89CB0),

          primary: const Color(0xFFE89CB0),

        ),



        elevatedButtonTheme: ElevatedButtonThemeData(

          style: ElevatedButton.styleFrom(

            backgroundColor: const Color(0xFFE89CB0),

            foregroundColor: Colors.white,


            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(30),

            ),


          ),

        ),


      ),




      // First screen
      home: const SplashScreen(),



      routes: {


        '/welcome': (context) =>

            const WelcomeScreen(),



        '/onboarding': (context) =>

            const OnboardingScreen(),



        '/login': (context) =>

            const LoginScreen(),



        '/register': (context) =>

            const RegisterScreen(),



        '/chatbot': (context) =>

            const ChatbotScreen(),



      },


    );


  }


}