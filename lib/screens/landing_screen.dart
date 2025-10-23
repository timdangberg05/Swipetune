import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:swipetune/screens/auth_page.dart';
import 'package:swipetune/screens/main_screen.dart';
import 'package:swipetune/screens/onboarding_screen.dart';
import 'package:swipetune/widgets/intro_animation.dart';
import 'package:swipetune/widgets/liquid_background.dart';
import 'package:swipetune/widgets/logo_choreographer.dart';
import '../services/auth_services.dart';

import '../providers/spotify_data_provider.dart';
import 'package:provider/provider.dart';

// Stelle sicher, dass SwipeAction definiert ist (z.B. in spotify_data_provider.dart)
// enum SwipeAction { like, dislike }

enum AppState { welcome, login, signup, onboarding, home }

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _timeController, _transitionController, _colorTransitionController, _spotifyAuthController, _authPageController, _backgroundMorphController, _homeController;
  late AnimationController _spotifySuccessController; // Controller für Haken-Animation

  AppState _appState = AppState.welcome;

  final ValueNotifier<int> _currentPageNotifier = ValueNotifier(0);
  final ValueNotifier<Offset?> _spotifyLogoCenterNotifier = ValueNotifier(null);
  final ScrollController _sharedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _transitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _colorTransitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _spotifyAuthController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _authPageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _backgroundMorphController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _homeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _spotifySuccessController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000)); // Dauer für Haken

    _checkExistingLogin();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _transitionController.forward();
    });
  }

  @override
  void dispose() {
    _timeController.dispose();
    _transitionController.dispose();
    _colorTransitionController.dispose();
    _spotifyAuthController.dispose();
    _authPageController.dispose();
    _backgroundMorphController.dispose();
    _homeController.dispose();
    _spotifySuccessController.dispose();
    _spotifyLogoCenterNotifier.dispose();
    _currentPageNotifier.dispose();
    _sharedScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingLogin() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final hasTokens = await AuthServices.tokenStore.hasValidTokens();
    if (hasTokens) {
      if (mounted) {
        _setAppState(AppState.home);
      }
    }
  }

  void _setAppState(AppState newState) {
    // Nur ändern, wenn der Status tatsächlich neu ist
    if (_appState == newState) return;

    setState(() {
      _appState = newState;
      if (newState == AppState.login || newState == AppState.signup) {
        _authPageController.forward();
      } else if (newState == AppState.home) {
         // Reset other controllers if necessary when going home
         _spotifyAuthController.reset();
         _spotifySuccessController.reset();
         _authPageController.reset();
        _homeController.forward();
      } else if (newState == AppState.welcome) {
        // Reset everything when going back to welcome
         _spotifyAuthController.reset();
         _spotifySuccessController.reset();
         _homeController.reset();
        _authPageController.reverse();
      }
    });
  }

  // --- KORRIGIERTE LOGIK FÜR DEN SPOTIFY FLOW ---
  void _toggleSpotifyFlow(bool isActive) async {
    if (isActive) {
      // 1. Start: Bubbles werden grün, "Connecting"-Logo erscheint
      _colorTransitionController.forward();
      _spotifyAuthController.forward();
      try {
        // 2. Warten auf den Web-Login
        await AuthServices.login();

        // 3. Erfolg! Starte die Haken-Animation
        if (mounted) {
          // Bubbles "butterweich" zurück zu lila/blau
          _colorTransitionController.reverse();

          // Starte die Haken-Animation und WARTE, bis sie fertig ist.
          await _spotifySuccessController.forward().orCancel; // orCancel ist wichtig!

          // 4. NACHDEM der Haken fertig ist, gehe zur Home-Seite.
          if (mounted && _spotifySuccessController.status == AnimationStatus.completed) {
             _setAppState(AppState.home);
          }
        }

      } catch (e) {
        // 5. Fehler: Alles zurücksetzen (nur wenn noch mounted)
        if (mounted) {
          _colorTransitionController.reverse();
          _spotifyAuthController.reverse();
          _spotifySuccessController.reset(); // Sicherstellen, dass Success zurückgesetzt wird
          _setAppState(AppState.welcome);
           // Optional: Fehlermeldung anzeigen
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Spotify login failed: ${e.toString()}'))
           );
        }
      } finally {
         // Sicherstellen, dass Controller zurückgesetzt werden, falls etwas schiefgeht
         if (mounted && _appState != AppState.home) {
             // Möglicherweise hier nichts tun oder nur bestimmte Controller zurücksetzen
         }
      }
    } else {
      // User hat "Cancel" gedrückt
      if (mounted) {
          _colorTransitionController.reverse();
          _spotifyAuthController.reverse();
          _spotifySuccessController.reset(); // Auch hier zurücksetzen
      }
    }
  }
  // --- ENDE DER KORRIGIERTEN LOGIK ---

  @override
  Widget build(BuildContext context) {
    ValueNotifier<SwipeAction?>? swipeNotifier;
    // Sicherstellen, dass der Provider nur im home state gelesen wird und existiert
    try {
      if (_appState == AppState.home) {
        swipeNotifier = context.read<SpotifyDataProvider>().swipeActionNotifier;
      }
    } catch (e) {
       // Provider noch nicht verfügbar, ignoriere
      swipeNotifier = null;
    }


    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          LiquidGlassBackground(
            time: _timeController,
            colorTransitionValue: _colorTransitionController.view,
            spotifyLogoCenterNotifier: _spotifyLogoCenterNotifier,
            // swipeNotifier sicher übergeben
            swipeActionNotifier: swipeNotifier, // Kann null sein, wird im Widget geprüft
            backgroundMorphController: _backgroundMorphController,
            homeTransitionController: _homeController.view,
          ),

          // --- Shader Warm-up Widget ---
          // Dieses Widget rendert 1 Frame lang die teuersten
          // Effekte in einem 1x1 Pixel-Container, um die Shader zu kompilieren.
          // Es wird nur einmal beim App-Start ausgeführt.
          FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 200)), // Warte 200ms
            builder: (context, snapshot) {
              // Rendert nur, bevor die Verzögerung vorbei ist
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Positioned.fill(
                  child: Opacity(
                    opacity: 0.0, // Absolut unsichtbar
                    child: IgnorePointer(
                      ignoring: true, // Nimmt keine Taps
                      child: Container(
                        width: 1, // Minimalgröße
                        height: 1,
                        child: Stack(
                          children: [
                            // 1. Wärmt den CustomPaint-Blur auf
                            CustomPaint(
                              painter: LiquidBlobPainter(
                                blobs: [],
                                morphValue: 0,
                                homeTransition: 0,
                              ),
                            ),
                            // 2. Wärmt den BackdropFilter (Glas-Effekt) auf
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                              child: Container(width: 1, height: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              // Verschwindet nach 200ms
              return const SizedBox.shrink();
            },
          ),
          // --- ENDE Shader Warm-up ---

          LogoChoreographer(
            introController: _transitionController,
            spotifyController: _spotifyAuthController,
            spotifySuccessController: _spotifySuccessController, // *** HIER KORRIGIERT ***
            authController: _authPageController,
            homeController: _homeController,
            currentPageNotifier: _currentPageNotifier,
            onCancelSpotify: () => _toggleSpotifyFlow(false),
            scrollController: _sharedScrollController,
          ),

          _buildUIForState(),
        ],
      ),
    );
  }

  Widget _buildUIForState() {
    switch (_appState) {
      case AppState.login:
      case AppState.signup:
        return AuthPage(
          initialMode: _appState == AppState.login ? AuthMode.login : AuthMode.signup,
          onBack: () => _setAppState(AppState.welcome),
          onLoginComplete: () => _setAppState(AppState.home),
          onSignUpComplete: () => _setAppState(AppState.onboarding),
        );
      case AppState.onboarding:
        return OnboardingScreen(
          backgroundMorphController: _backgroundMorphController,
          onComplete: () => _setAppState(AppState.home),
        );
      case AppState.home:
        return MainScreen(
          transitionController: _homeController,
          currentPageNotifier: _currentPageNotifier,
          sharedScrollController: _sharedScrollController,
        );
      case AppState.welcome:
      default:
        return IntroAnimation(
          controller: _transitionController,
          spotifyAuthController: _spotifyAuthController,
          authPageController: _authPageController,
          onLogin: () => _setAppState(AppState.login),
          onSignUp: () => _setAppState(AppState.signup),
          onSpotifyLogin: () => _toggleSpotifyFlow(true),
        );
    }
  }
}
