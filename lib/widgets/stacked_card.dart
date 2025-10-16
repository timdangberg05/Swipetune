import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:swipetune/models/Track.dart';
import 'song_card.dart';

class StackedCardUpwards extends StatelessWidget {
  final Track track;
  final double position;

  const StackedCardUpwards({
    super.key,
    required this.track,
=======
import '../homepage_songs/song.dart';
import 'song_card.dart';

// Stellt die `GlassSongCard`-Widgets als Stapel im Hintergrund dar.
class GlassStackedCard extends StatelessWidget {
  final Song song;
  final double position;

  const GlassStackedCard({
    super.key,
    required this.song,
>>>>>>> frontend
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final double scale = 1 - (position * 0.05);
    final double verticalOffset = -position * 25;
    final double opacity = 1 - (position * 0.15);
=======
    final double scale = 1.0 - (position * 0.04);
    final double verticalOffset = -position * 20.0;
>>>>>>> frontend

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Transform.scale(
        scale: scale,
<<<<<<< HEAD
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.55,
            child: SongCard(track: track),
          ),
=======
        
        child: GlassSongCard(
          song: song,
          isPlaying: false,       // Standardwert, da die Karte nicht interaktiv ist
          onPlayPause: () {},     // Leere Funktion, da kein Klick benötigt wird
>>>>>>> frontend
        ),
      ),
    );
  }
}
<<<<<<< HEAD
=======

>>>>>>> frontend
