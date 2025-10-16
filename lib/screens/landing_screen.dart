import 'package:flutter/material.dart';
import 'package:swipetune/screens/auth_page.dart';
import 'package:swipetune/screens/main_screen.dart';
import 'package:swipetune/screens/onboarding_screen.dart';
import 'package:swipetune/widgets/intro_animation.dart';
import 'package:swipetune/widgets/liquid_background.dart';
import 'package:swipetune/widgets/logo_choreographer.dart';
import '../services/auth_services.dart';

enum AppState { welcome, login, signup, onboarding, home }

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _timeController, _transitionController, _colorTransitionController, _spotifyAuthController, _authPageController, _backgroundMorphController, _homeController;
  AppState _appState = AppState.welcome;
  
  // ZENTRALE STATE-VERWALTUNG um den teilt dem LogoChoreographer mit, welche Seite aktiv ist
  // und ermöglicht so stabile Header-Animationen.
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier(0);
  final ValueNotifier<Offset?> _spotifyLogoCenterNotifier = ValueNotifier(null);

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
    // Die Notifier von 'incoming' werden korrekt disposed.
    _spotifyLogoCenterNotifier.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  // NEU: Die komplette Auto-Login-Funktion aus 'current' wurde übernommen.
  // Sie wurde angepasst, um den 'home'-State von 'incoming' zu verwenden.
  Future<void> _checkExistingLogin() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final hasTokens = await AuthServices.tokenStore.hasValidTokens();
    if (hasTokens) {
      if (mounted) {
        _setAppState(AppState.home); // Verwendet 'home' statt 'homepage'
      }
    }
  }

  // Die setAppState-Logik von 'incoming' wurde beibehalten.
  void _setAppState(AppState newState) {
    setState(() {
      _appState = newState;
      if (newState == AppState.login || newState == AppState.signup) {
        _authPageController.forward();
      } else if (newState == AppState.home) {
        // Stellt sicher, dass die HomePage-Animation startet
        _homeController.forward();
      } else if (newState == AppState.welcome) {
        _authPageController.reverse();
      }
    });
  }

  void _toggleSpotifyFlow(bool isActive) async {
    if (isActive) {
      _colorTransitionController.forward();
      _spotifyAuthController.forward();
      try {
        await AuthServices.login();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) _setAppState(AppState.home);
      } catch (e) {
        if (mounted) {
          _colorTransitionController.reverse();
          _spotifyAuthController.reverse();
          _setAppState(AppState.welcome);
        }
      }
    } else {
      _colorTransitionController.reverse();
      _spotifyAuthController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          LiquidGlassBackground(
            time: _timeController,
            colorTransitionValue: _colorTransitionController.view,
            spotifyLogoCenterNotifier: _spotifyLogoCenterNotifier,
            backgroundMorphController: _backgroundMorphController,
            homeTransitionController: _homeController.view,
          ),
          
          // Der LogoChoreographer erhält jetzt den Notifier, um auf Seitenwechsel zu reagieren.
          LogoChoreographer(
            introController: _transitionController,
            spotifyController: _spotifyAuthController,
            authController: _authPageController,
            homeController: _homeController,
            currentPageNotifier: _currentPageNotifier, // HIER WIRD DER STATE ÜBERGEBEN
            onCancelSpotify: () => _toggleSpotifyFlow(false),
          ),

          // Der eigentliche UI-Inhalt
          _buildUIForState(),
        ],
      ),
    );
  }

  // GEMERGT: Die UI-Building-Logik.
  // Nutzt die saubere Struktur von 'incoming' und ergänzt die 'keys' von 'current',
  // die für den AnimatedSwitcher wichtig sind.
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
        // Der MainScreen erhält den Notifier, um ihn bei Seitenwechsel zu aktualisieren.
        return MainScreen(
          transitionController: _homeController,
          currentPageNotifier: _currentPageNotifier, // HIER WIRD DER STATE ÜBERGEBEN
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