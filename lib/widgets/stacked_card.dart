import 'dart:ui'; // Import für lerpDouble
import 'package:flutter/material.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';
import 'song_card.dart';

/// Stacked card for showing next song in the background
class GlassStackedCard extends StatelessWidget {
  final FirebaseTrack track;
  final double position;
  final double swipeProgress; // <-- NEU

  const GlassStackedCard({
    super.key,
    required this.track,
    required this.position,
    required this.swipeProgress, // <-- NEU
  });

  @override
  Widget build(BuildContext context) {
    // progress ist der Swipe-Fortschritt von -1.0 bis 1.0
    // Wir brauchen den absoluten Wert (0.0 bis 1.0)
    final progress = swipeProgress.abs();

    // Basis-Werte für die Karte (wie vorher)
    final double scaleFactor = 1.0 - (position * 0.04);
    final double verticalOffsetFactor = -position * 20.0;
    final double opacityFactor = 1.0 - (position * 0.2);

    // --- NEUE LIVE ANIMATION ---
    // 'lerp' = linear interpolation
    // Wenn progress=0, verwende den Basis-Wert. Wenn progress=1 (voll geswiped),
    // verwende den Wert der NÄCHSTEN Position (also position - 1).

    // Karte 1 skaliert von 0.96 (Basis) zu 1.0 (Ziel)
    final double nextScale = 1.0 - ((position - 1) * 0.04);
    final double liveScale = lerpDouble(scaleFactor, nextScale, progress)!;

    // Karte 1 bewegt sich von -20 (Basis) zu 0 (Ziel)
    final double nextVerticalOffset = -(position - 1) * 20.0;
    final double liveVerticalOffset = lerpDouble(verticalOffsetFactor, nextVerticalOffset, progress)!;

    // Karte 1 faded von 0.8 (Basis) zu 1.0 (Ziel)
    final double nextOpacity = (position == 1) ? 1.0 : 1.0 - ((position - 1) * 0.2);
    final double liveOpacity = lerpDouble(opacityFactor, nextOpacity, progress)!;
    // --- ENDE NEU ---

    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(0, liveVerticalOffset),
        child: Transform.scale(
          scale: liveScale,
          child: Opacity(
            opacity: liveOpacity.clamp(0.0, 1.0), // Clamp für Sicherheit
            child: GlassSongCard(
              track: track,
              isPlaying: false,
              onPlayPause: () {}, // Non-interactive in stack
            ),
          ),
        ),
      ),
    );
  }
}
