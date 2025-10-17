import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:swipetune/API/SongService.dart';
import 'package:swipetune/API/SpotifyApiClient.dart';
import 'package:swipetune/providers/spotify_data_provider.dart';

import 'package:swipetune/screens/landing_screen.dart';
import 'package:swipetune/screens/auth_page.dart';
import 'package:swipetune/screens/library_screen.dart';
import 'package:swipetune/screens/main_screen.dart'; 
import 'package:swipetune/screens/onboarding_screen.dart';
import 'package:swipetune/screens/settings_screen.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => SpotifyApiClient()),
        Provider(create: (context) => SongService(context.read())),
        ChangeNotifierProvider(
          create: (context) => SpotifyDataProvider(context.read()),
        ),
      ],
      child: const SwipetuneApp(),
    ),
  );
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

      //Start Route
      initialRoute: '/landing',

      
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/library': (context) => const LibraryScreen(),
        '/settings': (context) => const SettingsScreen(),
        
      },
    );
  }
}
