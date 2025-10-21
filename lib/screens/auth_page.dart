import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:swipetune/widgets/auth_widgets.dart';

enum AuthMode { login, signup }

class AuthPage extends StatefulWidget {
  final AuthMode initialMode;
  final VoidCallback onBack;
  final VoidCallback onSignUpComplete;
  final VoidCallback onLoginComplete;

  const AuthPage({
    super.key,
    required this.initialMode,
    required this.onBack,
    required this.onSignUpComplete,
    required this.onLoginComplete,
  });

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  void _switchMode(AuthMode newMode) {
    setState(() {
      _currentMode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: widget.onBack,
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _currentMode == AuthMode.login
                        ? LoginPanel(
                            key: const ValueKey('login'),
                            onSignUp: () => _switchMode(AuthMode.signup),
                            onLoginComplete: widget.onLoginComplete,
                          )
                        : SignUpPanel(
                            key: const ValueKey('signup'),
                            onLogin: () => _switchMode(AuthMode.login),
                            onSignUpComplete: widget.onSignUpComplete,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

