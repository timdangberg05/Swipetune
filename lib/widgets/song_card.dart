import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:swipetune/models/Track.dart';
import '../homepage_songs/song.dart';
import 'player_bar.dart';

/// Modern glass-morphism song card with integrated music player
class GlassSongCard extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const GlassSongCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onPlayPause, 
  });

  @override
  Widget build(BuildContext context) {
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
            // Backdrop blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
            // Glass container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Cover image
            Image.network(
              track.albumImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(),
            ),
            // Gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Integrated liquid music player
            LiquidMusicPlayer(
              track: track,
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
          child: Icon(
            Icons.music_note_rounded,
            size: 60,
            color: Colors.white38,
          ),
        ),
      );
}
