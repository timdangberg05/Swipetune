import 'package:flutter/material.dart';
import '../homepage_songs/song.dart';
import 'song_card.dart';

// Stellt die `GlassSongCard`-Widgets als Stapel im Hintergrund dar.
class GlassStackedCard extends StatelessWidget {
  final Song song;
  final double position;

  const GlassStackedCard({
    super.key,
    required this.song,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = 1.0 - (position * 0.04);
    final double verticalOffset = -position * 20.0;

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Transform.scale(
        scale: scale,
        
        child: GlassSongCard(
          song: song,
          isPlaying: false,       // Standardwert, da die Karte nicht interaktiv ist
          onPlayPause: () {},     // Leere Funktion, da kein Klick benötigt wird
        ),
      ),
    );
  }
}

