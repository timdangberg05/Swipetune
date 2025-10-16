<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:swipetune/models/Track.dart';
import '/homepage_songs/song.dart';

class PlayerBar extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const PlayerBar({
    super.key,
    required this.track,
=======
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../homepage_songs/song.dart';

/// Ein animierter Musik-Player im Liquid-Glass-Stil in dieser Swipe Karter
class LiquidMusicPlayer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const LiquidMusicPlayer({
    super.key,
    required this.song,
>>>>>>> frontend
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: isPlaying ? 0.3 : 0.0,
              backgroundColor: Colors.grey.shade800,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.green.shade400),
              minHeight: 3,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track.albumImageUrl ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      // Fallback, wenn das Bild nicht geladen werden kann
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.white12,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white54,
                            size: 28,
                          ),
                        );
                      },
                      // Optional: Lade-Indikator, während das Bild geladen wird
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.white12,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () {},
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: onPlayPause,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
=======
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Songtitel und Künstler
          Text(
            song.title,
            style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            song.artist,
            style: GoogleFonts.manrope(fontSize: 16, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(), // Flexibler Abstand

          // Player-Steuerung und Fortschrittsanzeige
          Row(
            children: [
              _buildPlayPauseButton(),
              const SizedBox(width: 16),
              Expanded(child: _buildProgressBar()),
            ],
          ),
        ],
      ),
    );
  }

  /// Der Play/Pause-Button mit Glaseffekt.
  Widget _buildPlayPauseButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
            onPressed: onPlayPause,
          ),
        ),
      ),
    );
  }

  /// Die animierte Fortschrittsanzeige.
  Widget _buildProgressBar() {
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: isPlaying ? 120 : 0, // Simuliert den Fortschritt
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.8),
              Colors.white.withOpacity(0.5),
            ],
          ),
>>>>>>> frontend
        ),
      ),
    );
  }
}
<<<<<<< HEAD
=======

>>>>>>> frontend
