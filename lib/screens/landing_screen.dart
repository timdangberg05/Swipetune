import 'package:flutter/material.dart';
import 'package:swipetune/screens/auth_page.dart';
import 'package:swipetune/screens/home_screen.dart';
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
  late AnimationController _timeController;
  late AnimationController _transitionController;
  late AnimationController _colorTransitionController;
  late AnimationController _spotifyAuthController;
  late AnimationController _authPageController;
  late AnimationController _backgroundMorphController;
  late AnimationController _homeController;

  AppState _appState = AppState.welcome;

  late final AuthServices _authService;
  
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
    _authService = AuthServices(clientId: 'deb60e6c420e48b789b7a205a25df95e', redirectUri: 'swipetune://callback', scopes: ['user-read-email','playlist-modify','playlist-modify-private','user-top-read']);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _transitionController.forward();
      }
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
    _spotifyLogoCenterNotifier.dispose();
    super.dispose();
  }

  void _setAppState(AppState newState) {
    setState(() {
      _appState = newState;
      if (newState == AppState.login || newState == AppState.signup) {
        _authPageController.forward();
      } else if (newState == AppState.onboarding) {
        _authPageController.reverse();
      } else if (newState == AppState.home) {
        _homeController.forward();
      }
      else {
        _authPageController.reverse();
      }
    });
  }

  void _toggleSpotifyFlow(bool isActive) async {
    final size = MediaQuery.of(context).size;
    final finalLogoYPosition = size.height * 0.35;
    final finalLogoXPosition = (size.width / 2) + 60; 

    if (isActive) {
      _spotifyLogoCenterNotifier.value = Offset(finalLogoXPosition, finalLogoYPosition + 30);
      _colorTransitionController.forward(from: 0.0);
      _spotifyAuthController.forward(from: 0.0);

      try
      {
        await _authService.login();
        await Future.delayed(Duration(microseconds: 500));
        if(mounted)
        {
          _setAppState(AppState.home);
        }
      }
      catch(e)
      {
        if(mounted)
        {
          _toggleSpotifyFlow(false);
        }
      }
    } else {
      _spotifyLogoCenterNotifier.value = null;
      _colorTransitionController.reverse(from: 1.0);
      _spotifyAuthController.reverse(from: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            LiquidGlassBackground(
              time: _timeController,
              colorTransitionValue: _colorTransitionController.view,
              spotifyLogoCenterNotifier: _spotifyLogoCenterNotifier,
              backgroundMorphController: _backgroundMorphController,
            ),
            
            LogoChoreographer(
              introController: _transitionController,
              spotifyController: _spotifyAuthController,
              authController: _authPageController,
              homeController: _homeController,
              onCancelSpotify: () => _toggleSpotifyFlow(false),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _buildUIForState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUIForState() {
    switch (_appState) {
      case AppState.login:
        return AuthPage(
          key: const ValueKey('loginPage'),
          initialMode: AuthMode.login,
          onBack: () => _setAppState(AppState.welcome),
          onLoginComplete: () => _setAppState(AppState.home),
          onSignUpComplete: () => _setAppState(AppState.onboarding),
        );
      case AppState.signup:
        return AuthPage(
          key: const ValueKey('signupPage'),
          initialMode: AuthMode.signup,
          onBack: () => _setAppState(AppState.welcome),
          onLoginComplete: () => _setAppState(AppState.home),
          onSignUpComplete: () => _setAppState(AppState.onboarding),
        );
      case AppState.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          backgroundMorphController: _backgroundMorphController,
          onComplete: () => _setAppState(AppState.home),
        );
       case AppState.home:
        return FadeTransition(
          opacity: _homeController,
          child: const HomePage(),
        );
      case AppState.welcome:
      default:
        return IntroAnimation(
          key: const ValueKey('intro'),
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

