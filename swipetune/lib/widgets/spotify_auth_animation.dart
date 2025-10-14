import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swipetune/widgets/auth_widgets.dart';

class SpotifyAuthAnimation extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onCancel;
  final double finalLogoYPosition;

  const SpotifyAuthAnimation({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.finalLogoYPosition,
  });

  @override
  Widget build(BuildContext context) {
    // KORRIGIERT: Feinjustiertes Intervall und lineare Kurve für einen nahtlosen Übergang.
    final finalLogoRowFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.6, 0.8, curve: Curves.linear))
    );

    final panelFade = Tween<double>(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    ));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Visibility(
          visible: controller.value > 0.0,
          child: Stack(
            children: [
              // Die finale, perfekt zentrierte Logo-Reihe
              Positioned(
                top: finalLogoYPosition,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: finalLogoRowFadeIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.waves_rounded, color: Colors.white, size: 60),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.5),
                        size: 30,
                      ),
                      const SizedBox(width: 20),
                      const FaIcon(
                        FontAwesomeIcons.spotify,
                        color: Color(0xFF1DB954),
                        size: 60,
                      ),
                    ],
                  ),
                ),
              ),
              
              Positioned(
                top: finalLogoYPosition + 120,
                left: 0,
                right: 0,
                child: Center(
                  child: FadeTransition(
                    opacity: panelFade,
                    child: (controller.value > 0.7)
                        ? SpotifyLoginPanel(onCancel: onCancel)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

