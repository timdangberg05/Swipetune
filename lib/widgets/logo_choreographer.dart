import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swipetune/widgets/auth_widgets.dart';

class LogoChoreographer extends StatelessWidget {
  final AnimationController introController;
  final AnimationController spotifyController;
  final AnimationController authController;
  final AnimationController homeController;
  final VoidCallback onCancelSpotify;

  const LogoChoreographer({
    super.key,
    required this.introController,
    required this.spotifyController,
    required this.authController,
    required this.homeController,
    required this.onCancelSpotify,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    
    // --- Animations-Definitionen ---
    final introCurve = CurvedAnimation(parent: introController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic));
    final spotifyCurve = CurvedAnimation(parent: spotifyController, curve: const Interval(0.2, 0.8, curve: Curves.easeInOutCubic));
    final authCurve = CurvedAnimation(parent: authController, curve: Curves.easeInOutCubic);
    final homeCurve = CurvedAnimation(parent: homeController, curve: Curves.easeInOutCubic);

    // Y-Position
    final introY = Tween<double>(begin: size.height / 2 - 40, end: size.height * 0.25).animate(introCurve);
    final spotifyY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.35).animate(spotifyCurve);
    final authY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.15).animate(authCurve);
    final homeY = Tween<double>(begin: size.height * 0.15, end: safeArea.top + 16).animate(homeCurve);

    // Größe
    final logoSize = Tween<double>(begin: 80.0, end: 60.0).animate(introCurve);
    final homeLogoSize = Tween<double>(begin: 60.0, end: 30.0).animate(homeCurve);

    // X-Positionen
    final swipetuneMoveX = Tween<double>(begin: 0, end: -75).animate(spotifyCurve);
    final homeMoveX = Tween<double>(begin: 0, end: -(size.width / 2) + 40).animate(homeCurve);
    
    // Fading
    final xFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: spotifyController, curve: const Interval(0.4, 0.9)));
    final spotifyFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: spotifyController, curve: const Interval(0.2, 0.8)));
    final panelFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: spotifyController, curve: const Interval(0.7, 1.0)));

    return AnimatedBuilder(
      animation: Listenable.merge([introController, spotifyController, authController, homeController]),
      builder: (context, child) {
        double currentY;
        if (homeController.value > 0) {
          currentY = homeY.value;
        } else if (spotifyController.value > 0) {
          currentY = spotifyY.value;
        } else if (authController.value > 0) {
          currentY = authY.value;
        } else {
          currentY = introY.value;
        }

        final currentSize = homeController.value > 0 ? homeLogoSize.value : logoSize.value;
        final currentX = homeController.value > 0 ? homeMoveX.value : swipetuneMoveX.value;

        // Bestimmt die Sichtbarkeit der Spotify-Elemente
        final isSpotifyVisible = spotifyController.value > 0 && homeController.value == 0;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: currentY,
              child: Transform.translate(
                offset: Offset(currentX, 0),
                child: Icon(Icons.waves_rounded, color: Colors.white, size: currentSize),
              ),
            ),
             // Positioniert die Spotify-spezifischen Elemente separat
            if (isSpotifyVisible)
              Positioned(
                top: spotifyY.value,
                child: Row(
                  children: [
                    SizedBox(width: swipetuneMoveX.value.abs() * 2), 
                    FadeTransition(
                      opacity: xFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 30),
                      ),
                    ),
                    FadeTransition(
                      opacity: spotifyFade,
                      child: const FaIcon(FontAwesomeIcons.spotify, color: Color(0xFF1DB945), size: 60),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: size.height * 0.35 + 120,
              child: FadeTransition(
                opacity: panelFade,
                child: (spotifyController.value > 0.7)
                    ? SpotifyLoginPanel(onCancel: onCancelSpotify)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

