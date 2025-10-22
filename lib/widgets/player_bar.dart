import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/models/Track.dart';

/// Animated music player with liquid glass design for the swipe card
class LiquidMusicPlayer extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final double titleOffset; // Offset für Slide-Animation
  final double controlsFade; // Fade für Controls

  const LiquidMusicPlayer({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onPlayPause,
    this.titleOffset = 0.0,
    this.controlsFade = 1.0, required Color textColor, required List<Shadow> textShadows,
  });

  @override
  Widget build(BuildContext context) {
    const textShadow = Shadow(
      offset: Offset(1.5, 1.5),
      blurRadius: 2.0,
      color: Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide-Animation für Songtitel & Artist (KEIN Fade!)
          Transform.translate(
            offset: Offset(0, titleOffset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [textShadow],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  track.artist,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.white70,
                    shadows: [textShadow],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Player controls mit Fade-Out
          Opacity(
            opacity: controlsFade, // Nur Controls faden
            child: Row(
              children: [
                _buildPlayPauseButton(),
                const SizedBox(width: 16),
                Expanded(child: _buildProgressBar()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Play/pause button with glass effect
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

  /// Animated progress bar
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
        width: isPlaying ? 120 : 0,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.8),
              Colors.white.withOpacity(0.5),
            ],
          ),
        ),
      ),
    );
  }
}
