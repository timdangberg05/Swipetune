import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swipetune/widgets/auth_widgets.dart';

class SpotifyAuthAnimation extends StatelessWidget {
  final Animation<double> controller;
  final VoidCallback onCancel;
  final double startY;
  final double endY;

  const SpotifyAuthAnimation({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.startY,
    required this.endY,
  });

  @override
  Widget build(BuildContext context) {
    // Gemeinsame Kurve für die Bewegung
    final moveCurve = CurvedAnimation(parent: controller, curve: const Interval(0.2, 0.8, curve: Curves.easeInOutCubic));

    // Tweens für die Position und das Fading
    final yPos = Tween<double>(begin: startY, end: endY).animate(moveCurve);
    final swipetuneMoveX = Tween<double>(begin: 0, end: -75).animate(moveCurve);
    
    // Cross-Fade Animationen mit linearer Kurve für Unsichtbarkeit
    final flyingLogoFade = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: controller, curve: const Interval(0.3, 0.6, curve: Curves.linear)));
    final finalRowFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: controller, curve: const Interval(0.3, 0.6, curve: Curves.linear)));

    final panelFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.7, 1.0, curve: Curves.easeIn)),
    );
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Visibility(
          visible: controller.value > 0.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Positioniert den gesamten Animations-Container
              Positioned(
                top: yPos.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Version 1: Das "fliegende" Logo, das sich bewegt und ausblendet
                    FadeTransition(
                      opacity: flyingLogoFade,
                      child: Transform.translate(
                        offset: Offset(swipetuneMoveX.value, 0),
                        child: const Icon(Icons.waves_rounded, color: Colors.white, size: 60),
                      ),
                    ),
                    // Version 2: Die finale, symmetrische Reihe, die einblendet
                    FadeTransition(
                      opacity: finalRowFade,
                      child: Row(
                        children: [
                           const Icon(Icons.waves_rounded, color: Colors.white, size: 60),
                           const SizedBox(width: 20),
                           Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 30),
                           const SizedBox(width: 20),
                           const FaIcon(FontAwesomeIcons.spotify, color: Color(0xFF1DB945), size: 60),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // "Connecting..." Box
              Positioned(
                top: endY + 120,
                child: FadeTransition(
                  opacity: panelFade,
                  child: (controller.value > 0.7)
                      ? SpotifyLoginPanel(onCancel: onCancel)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

