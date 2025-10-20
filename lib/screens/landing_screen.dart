import 'package:flutter/material.dart';
import 'package:swipetune/screens/main_screen.dart';

import 'package:swipetune/widgets/intro_animation.dart';
import 'package:swipetune/widgets/liquid_background.dart';
import 'package:swipetune/widgets/logo_choreographer.dart';
import '../services/auth_services.dart';

enum AppState { welcome, home }

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _timeController, _transitionController, _colorTransitionController, _spotifyAuthController, _backgroundMorphController, _homeController;
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
    _backgroundMorphController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _homeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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
    _backgroundMorphController.dispose();
    _homeController.dispose();
    _spotifyLogoCenterNotifier.dispose();
    _currentPageNotifier.dispose();
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
    setState(() {
      _appState = newState;
      if (newState == AppState.home) {
        _homeController.forward();
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
          
          LogoChoreographer(
            introController: _transitionController,
            spotifyController: _spotifyAuthController,
            authController: _spotifyAuthController,
            homeController: _homeController,
            currentPageNotifier: _currentPageNotifier,
            onCancelSpotify: () => _toggleSpotifyFlow(false),
          ),

          // Der eigentliche UI-Inhalt
          _buildUIForState(),
        ],
      ),
    );
  }

  Widget _buildUIForState() {
    switch (_appState) {
      case AppState.home:
        return MainScreen(
          transitionController: _homeController,
          currentPageNotifier: _currentPageNotifier,
        );
      case AppState.welcome:
      default:
        return IntroAnimation(
          controller: _transitionController,
          spotifyAuthController: _spotifyAuthController,
          onSpotifyLogin: () => _toggleSpotifyFlow(true),
        );
    }
  }
}
