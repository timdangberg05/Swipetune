import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:swipetune/models/Track.dart';
import 'package:swipetune/services/preview_service.dart';

/// Animated music player with liquid glass design for the swipe card
class LiquidMusicPlayer extends StatefulWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final double titleOffset; // Offset für Slide-Animation
  final double controlsFade; // Fade für Controls
  final AudioPlayer player;

  const LiquidMusicPlayer({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onPlayPause,
    this.titleOffset = 0.0,
    this.controlsFade = 1.0, required Color textColor, required List<Shadow> textShadows,
    required this.player,
  });

  


  @override
  State<LiquidMusicPlayer> createState() => _LiquidMusicPlayerState();

}

class _LiquidMusicPlayerState extends State<LiquidMusicPlayer>{

  
  void onPlayPause(){
    if(widget.player.playing){
      widget.player.pause();
    }else{
      widget.player.play();
    }
  }
  
  @override
  void dispose(){
    widget.player.dispose();
    super.dispose();
  }

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
            offset: Offset(0,   widget.titleOffset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.track.name,
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
                  widget.track.artist,
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
            opacity: widget.controlsFade, // Nur Controls faden
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
    return StreamBuilder<PlayerState>(
        stream: widget.player.playerStateStream,
        builder: (context, snapshot){
          final playerState = snapshot.data;
          final isPlaying = playerState?.playing ?? false;
          final processingState = playerState?.processingState;

          if(processingState == ProcessingState.loading || processingState == ProcessingState.buffering){
            return Container(
              width: 56,
              height: 56,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white)
              )
            );
          }

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
    );
    
    
    
  }

  /// Animated progress bar
  /// Animated progress bar
  Widget _buildProgressBar() {
    // 1. StreamBuilder lauscht auf die Position des Players
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        // Aktuelle Position aus dem Stream (oder 0, wenn noch nichts da ist)
        final position = snapshot.data ?? Duration.zero;
        // Gesamtdauer des Tracks direkt vom Player holen
        final totalDuration = widget.player.duration ?? Duration.zero;

        // Berechne den Fortschritt als Wert zwischen 0.0 und 1.0
        double progress = 0.0;
        if (totalDuration.inMilliseconds > 0) {
          progress = position.inMilliseconds / totalDuration.inMilliseconds;
        }

        return Container(
          height: 56,
          //padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          // 2. LayoutBuilder gibt uns die maximale Breite für die Berechnung
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Der Hintergrund des Balkens
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Der animierte Vordergrund, der den Fortschritt anzeigt
                  Container(
                    width: constraints.maxWidth * progress, // 3. Breite dynamisch berechnen
                    height: 56,
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
                ],
              );
            },
          ),
        );
      },
    );
  }
}