import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'action_buttons.dart';

class IntroAnimation extends StatelessWidget {
  final AnimationController controller;
  final AnimationController spotifyAuthController;
  final AnimationController authPageController;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final VoidCallback onSpotifyLogin;

  const IntroAnimation({
    super.key,
    required this.controller,
    required this.spotifyAuthController,
    required this.authPageController,
    required this.onLogin,
    required this.onSignUp,
    required this.onSpotifyLogin,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    final textFade = CurvedAnimation(parent: controller, curve: const Interval(0.4, 0.9, curve: Curves.easeOut));
    final buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );

    final spotifyFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: spotifyAuthController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut))
    );
    final authFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: authPageController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut))
    );
    
    return AnimatedBuilder(
      animation: Listenable.merge([controller, spotifyAuthController, authPageController]),
      builder: (context, child) {
        final bool isVisible = spotifyAuthController.value == 0 && authPageController.value == 0;

        // IgnorePointer verhindert "Ghost Clicks", wenn die UI ausgeblendet ist
        return IgnorePointer(
          ignoring: !isVisible,
          child: FadeTransition(
            opacity: isVisible ? const AlwaysStoppedAnimation(1.0) : (spotifyAuthController.value > 0 ? spotifyFadeOut : authFadeOut),
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: size.height * 0.25 + 60 + 16,
            child: FadeTransition(
              opacity: textFade,
              child: Column(
                children: [
                  Text("Swipetune",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2),
                  ),
                  const SizedBox(height: 16),
                  Text("Sign up or log in to begin your sonic journey.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: safeArea.bottom + 20,
            left: 24,
            right: 24,
            child: SlideTransition(
              position: buttonsSlide,
              child: FadeTransition(
                opacity: textFade,
                child: Column(
                  children: [
                    ActionButton(text: "Sign up free", accentColor: const Color(0xFF9B51E0), onTap: onSignUp),
                    const SizedBox(height: 16),
                    SpotifyButton(onTap: onSpotifyLogin),
                    const SizedBox(height: 8),
                    TextButton(
                      child: const Text("Log in", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      onPressed: onLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

