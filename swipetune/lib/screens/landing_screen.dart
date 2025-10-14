import 'package:flutter/material.dart';
import 'package:swipetune/widgets/auth_widgets.dart';
import 'package:swipetune/widgets/intro_animation.dart';
import 'package:swipetune/widgets/liquid_background.dart';
import 'package:swipetune/widgets/spotify_auth_animation.dart';
import 'home_screen.dart';

enum AuthState { intro, welcome, login, signup }

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

  AuthState _authState = AuthState.intro;
  bool _isSpotifyFlowActive = false;
  
  final ValueNotifier<Offset?> _spotifyLogoCenterNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _transitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _colorTransitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _spotifyAuthController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500)); 

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _authState = AuthState.welcome);
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
    _spotifyLogoCenterNotifier.dispose();
    super.dispose();
  }

  void _setAuthState(AuthState newState) {
    if (_isSpotifyFlowActive) {
      _toggleSpotifyFlow(false);
    }
    setState(() {
      _authState = newState;
    });
  }

  void _toggleSpotifyFlow(bool isActive) {
    final size = MediaQuery.of(context).size;
    final finalLogoYPosition = size.height * 0.35;
    final finalLogoXPosition = (size.width / 2) + 65 + 15 + 30;

    setState(() {
      _isSpotifyFlowActive = isActive;
      if (_isSpotifyFlowActive) {
        _spotifyLogoCenterNotifier.value = Offset(finalLogoXPosition, finalLogoYPosition + 30);
        _colorTransitionController.forward(from: 0.0);
        _spotifyAuthController.forward(from: 0.0);
        if (_authState == AuthState.login || _authState == AuthState.signup) {
          _authState = AuthState.welcome;
        }
      } else {
        _spotifyLogoCenterNotifier.value = null;
        _colorTransitionController.reverse(from: 1.0);
        _spotifyAuthController.reverse(from: 1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final finalLogoYPosition = size.height * 0.35;
    final startingYPosition = size.height * 0.25;

    final introLogoMoveY = Tween<double>(begin: size.height / 2 - 40, end: startingYPosition)
        .animate(CurvedAnimation(parent: _transitionController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic)));
    
    final spotifyLogoMoveY = Tween<double>(begin: startingYPosition, end: finalLogoYPosition)
        .animate(CurvedAnimation(parent: _spotifyAuthController, curve: const Interval(0.2, 0.7, curve: Curves.easeInOutCubic)));
    
    final spotifyLogoMoveX = Tween<double>(begin: 0, end: -65.0) 
        .animate(CurvedAnimation(parent: _spotifyAuthController, curve: const Interval(0.2, 0.7, curve: Curves.easeInOutCubic)));

    final logoSize = Tween<double>(begin: 80.0, end: 60.0)
        .animate(CurvedAnimation(parent: _transitionController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic)));

    // KORRIGIERT: Feinjustiertes Intervall und lineare Kurve, passend zur Einblend-Animation.
    final flyingLogoFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _spotifyAuthController, curve: const Interval(0.4, 0.7, curve: Curves.linear))
    );

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
            ),
            
            AnimatedBuilder(
              animation: Listenable.merge([_transitionController, _spotifyAuthController]),
              builder: (context, child) {
                final currentY = _spotifyAuthController.isAnimating || _spotifyAuthController.isCompleted 
                    ? spotifyLogoMoveY.value 
                    : introLogoMoveY.value;
                final currentX = spotifyLogoMoveX.value;

                return Positioned(
                  top: currentY,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: flyingLogoFadeOut,
                    child: Transform.translate(
                      offset: Offset(currentX, 0),
                      child: Icon(Icons.waves_rounded, color: Colors.white, size: logoSize.value),
                    ),
                  ),
                );
              },
            ),

            IntroAnimation(
              controller: _transitionController,
              spotifyAuthController: _spotifyAuthController,
              onLogin: () => _setAuthState(AuthState.login),
              onSignUp: () => _setAuthState(AuthState.signup),
              onSpotifyLogin: () => _toggleSpotifyFlow(true),
            ),
            
            SpotifyAuthAnimation(
              controller: _spotifyAuthController,
              onCancel: () => _toggleSpotifyFlow(false),
              finalLogoYPosition: finalLogoYPosition, 
            ),
            
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: _buildUIForState(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUIForState() {
    if (_isSpotifyFlowActive) return const SizedBox.shrink();
    switch (_authState) {
      case AuthState.login:
        return AuthGlassPanel(
          key: const ValueKey('login'),
          onClose: () => _setAuthState(AuthState.welcome),
          child: LoginPanel(onSignUp: () => _setAuthState(AuthState.signup)),
        );
      case AuthState.signup:
        return AuthGlassPanel(
          key: const ValueKey('signup'),
          onClose: () => _setAuthState(AuthState.welcome),
          child: SignUpPanel(onLogin: () => _setAuthState(AuthState.login)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

