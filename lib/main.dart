import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/personal_album.dart';
import 'package:swipetune/API/SongService.dart';
import 'package:swipetune/API/SpotifyApiClient.dart';
import 'package:swipetune/providers/spotify_data_provider.dart';
import 'package:swipetune/providers/user_provider.dart';
import 'package:swipetune/screens/landing_screen.dart';
import 'package:swipetune/screens/auth_page.dart';
import 'package:swipetune/screens/library_screen.dart';
import 'package:swipetune/screens/liked_songs_screen.dart';
import 'package:swipetune/screens/main_screen.dart';
import 'package:swipetune/screens/onboarding_screen.dart';
import 'package:swipetune/screens/settings_screen.dart';
import 'package:swipetune/services/playlist_service.dart';
import 'package:swipetune/services/user_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PersonalAlbumAdapter());
  await Hive.openBox<PersonalAlbum>('personal_albums');
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => SpotifyApiClient()),
        Provider(
          create: (context) => SongService(
            context.read<SpotifyApiClient>()
          ),
        ),
        Provider(
          create: (context) => PlaylistService(
            context.read<SpotifyApiClient>()
          )
        ),
        Provider(
          create: (context) => UserService(
            context.read<SpotifyApiClient>()
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SpotifyDataProvider(
            context.read<SongService>(),
            context.read<PlaylistService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(
            context.read<UserService>()
          ),
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
        '/liked_songs': (context) => const LikedSongsScreen(),

      },
    );
  }
}
