import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/screens/landing_screen.dart';



void main() {
  runApp(const SwipetuneApp());
}

class SwipetuneApp extends StatelessWidget {
  const SwipetuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipetune',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0E),
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      ),
      home: const LandingScreen(),
    );
  }
}