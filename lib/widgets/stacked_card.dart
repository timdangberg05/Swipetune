import 'package:flutter/material.dart';
import '/homepage_songs/song.dart';
import 'song_card.dart';

class StackedCardUpwards extends StatelessWidget {
  final Song song;
  final double position;

  const StackedCardUpwards({
    super.key,
    required this.song,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = 1 - (position * 0.05);
    final double verticalOffset = -position * 25;
    final double opacity = 1 - (position * 0.15);

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.55,
            child: SongCard(song: song),
          ),
        ),
      ),
    );
  }
}
