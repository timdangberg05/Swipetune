import 'package:flutter/material.dart';
import '../homepage_songs/song.dart';
import 'song_card.dart';

/// Stacked card for showing next song in the background
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
    final double opacity = 1.0 - (position * 0.2);

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: GlassSongCard(
            song: song,
            isPlaying: false,
            onPlayPause: () {}, // Non-interactive in stack
          ),
        ),
      ),
    );
  }
}
