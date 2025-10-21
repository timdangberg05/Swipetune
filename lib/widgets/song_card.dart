import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/models/Track.dart';
import 'player_bar.dart';

class GlassSongCard extends StatefulWidget {
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
  State<GlassSongCard> createState() => _GlassSongCardState();
}

class _GlassSongCardState extends State<GlassSongCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  late final AnimationController _controller;
  late final Animation<double> _liftAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _controlsFadeAnim;
  late final Animation<double> _titleSlideAnim;
  late final Animation<double> _downShiftAnim;
  late final Animation<double> _infoFadeAnim;
  late final Animation<double> _detailsSlideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Karte hebt leicht ab (nach oben)
    _liftAnim = Tween<double>(begin: 0, end: -80).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // Karte skaliert leicht
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    // Fade-Out Animation NUR für Play-Button & Progress-Bar
    _controlsFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
      ),
    );

    // Titel & Artist sliden nach oben (KEIN Fade!)
    _titleSlideAnim = Tween<double>(begin: 0, end: -433).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
      ),
    );

    // Karte verschiebt sich leicht nach unten beim Expandieren
    _downShiftAnim = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Fade-In für Extra-Infos
    _infoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _detailsSlideAnim = Tween<double>(begin: 50, end: -20).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
      ),
    );

  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = 20.0;
    final collapsedWidth = (screenSize.width * 0.83).clamp(300.0, 420.0);
    final collapsedHeight = collapsedWidth * 1.65;

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final lift = _liftAnim.value;
          final scale = _scaleAnim.value;
          final controlsFade = _controlsFadeAnim.value;
          final titleSlide = _titleSlideAnim.value;
          final downShift = _downShiftAnim.value;

          return Transform.translate(
            offset: Offset(0, lift + downShift),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: collapsedWidth * (_isExpanded ? 1.05 : 1.0),
                height: collapsedHeight * (_isExpanded ? 1.08 : 1.0),
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blur Background
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(color: Colors.transparent),
                      ),

                      // Glas-Effekt Layer
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2.5,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),


                      // Album Cover
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.network(
                          widget.track.albumImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverFallback(),
                        ),
                      ),

                      // Dunkler Verlauf unten
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4), // Weißer, halbtransparenter Rand
                            width: 3, // Dicke des Rands
                          ),
                          // gradient: LinearGradient(
                          //   colors: [
                          //     Colors.white.withOpacity(0.08),
                          //     Colors.white.withOpacity(0.05),
                          //   ],
                          //   begin: Alignment.topLeft,
                          //   end: Alignment.bottomRight,
                          // ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 30, // für leichtes Leuchten
                              spreadRadius: 1,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),

                      // Player-Bar mit separatem Fade für Controls
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: LiquidMusicPlayer(
                          track: widget.track,
                          isPlaying: widget.isPlaying,
                          onPlayPause: widget.onPlayPause,
                          titleOffset: titleSlide, 
                          controlsFade: controlsFade, 
                        ),
                      ),

                      // Extra Infos beim Expand
                      Positioned(
                        bottom: 50,
                        left: 25,
                        right: 25,
                        child: IgnorePointer(
                          ignoring: !_isExpanded,
                          child: Transform.translate(
                            offset: Offset(0, _detailsSlideAnim.value),
                            child: Opacity(
                              opacity: _infoFadeAnim.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(Icons.album, "Album", widget.track.albumName),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.calendar_today, "Release", widget.track.releaseDate),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.trending_up, "Popularity", "${widget.track.popularity}/100"),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(Icons.audiotrack, "Preview", widget.track.previewUrl != null ? "Available" : "Not available"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Text(
        "$label:",
        style: GoogleFonts.manrope(
          color: Colors.white,           // Weiß, gut sichtbar
          fontWeight: FontWeight.w700,   // gleiche Gewichtung wie im Player
          fontSize: 16,                  // gleiche Größe wie im Player für Subtext
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.manrope(
            color: Colors.white,         // Weiß, klar sichtbar
            fontWeight: FontWeight.w600, // etwas leichter als Label
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

}