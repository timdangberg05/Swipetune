import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'action_buttons.dart';

class IntroAnimation extends StatelessWidget {
  final AnimationController controller;
  final AnimationController spotifyAuthController;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final VoidCallback onSpotifyLogin;

  const IntroAnimation({
    super.key,
    required this.controller,
    required this.spotifyAuthController,
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

    // Animationen für das Ausblenden der UI-Elemente
    final uiFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: spotifyAuthController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut))
    );
     final uiSlideDown = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 0.5)).animate(
      CurvedAnimation(parent: spotifyAuthController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut))
    );
    
    return AnimatedBuilder(
      animation: Listenable.merge([controller, spotifyAuthController]),
      builder: (context, child) {
        // Blendet die gesamte UI aus, wenn die Spotify-Animation aktiv ist
        return FadeTransition(
          opacity: uiFadeOut,
          child: SlideTransition(
            position: uiSlideDown,
            child: Stack(
              children: [
                // Der Text-Block
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
                
                // Die Buttons
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
          ),
        );
      },
    );
  }
}

