import 'dart:ui';
import 'package:flutter/material.dart';
import '../homepage_songs/song.dart';
import 'player_bar.dart'; 

// überarbeitete Song-Karte, die jetzt den LiquidMusicPlayer integrier
class GlassSongCard extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const GlassSongCard({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    // Media Query für responsive Kartengröße
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = (screenSize.width * 0.85).clamp(300.0, 420.0);
    final cardHeight = cardWidth * 1.5;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Der Unschärfe-Effekt, der den Hintergrund durchscheinen lässt
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
            // Der Glas-Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Cover-Bild (wird vom Player überlagert)
            Image.network(
              song.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(),
            ),
            // Verlauf für bessere Lesbarkeit
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Der neue Liquid Music Player
            LiquidMusicPlayer(
              song: song,
              isPlaying: isPlaying,
              onPlayPause: onPlayPause,
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback() => Container(
        color: Colors.grey.shade900.withOpacity(0.5),
        child: const Center(
          child: Icon(Icons.music_note_rounded, size: 60, color: Colors.white38),
        ),
      );
}

