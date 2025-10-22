import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:swipetune/API/SongService.dart';
import 'package:swipetune/API/SpotifyApiClient.dart';
import 'package:swipetune/models/Track.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final Color _textColor = Colors.white;

  late final AnimationController _controller;
  late final Animation<double> _liftAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _controlsFadeAnim;
  late Animation<double> _titleSlideAnim;
  late final Animation<double> _downShiftAnim;
  late final Animation<double> _infoFadeAnim;
  late final AudioPlayer player;
  late final SongService songservice;
  late final SpotifyApiClient apiclient;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _liftAnim = Tween<double>(begin: 0, end: -80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _controlsFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _titleSlideAnim = const AlwaysStoppedAnimation(0);

    _downShiftAnim = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _infoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
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

  void initPlayer() async {
    player = AudioPlayer();
    apiclient = SpotifyApiClient();
    songservice = SongService(apiclient);
    String? previewUrl = await songservice.getDeezerPreviewUrl(widget.track); 
    if(previewUrl != null){
      player.setUrl(previewUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = 20.0;
    final collapsedWidth = (screenSize.width * 0.83).clamp(300.0, 420.0);
    final collapsedHeight = collapsedWidth * 1.65;
    final topMargin = _isExpanded ? 35.0 : 20.0;
    
    initPlayer();
    
    

    return LayoutBuilder(
      builder: (context, constraints) {
        final dynamicSlide = -constraints.maxHeight * 0.46;

        // Animation des Songtitels synchron zur Card
        _titleSlideAnim = Tween<double>(begin: 0, end: dynamicSlide).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );

        return GestureDetector(
          onTap: _toggleExpand,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final lift = _liftAnim.value;
              final scale = _scaleAnim.value;
              final controlsFade = _controlsFadeAnim.value;
              final downShift = _downShiftAnim.value;
              double titleSlide =
                  _titleSlideAnim.value.clamp(dynamicSlide, 0);

              return Transform.translate(
                offset: Offset(0, lift + downShift),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: RepaintBoundary(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      width: collapsedWidth * (_isExpanded ? 1.05 : 1.0),
                      height: collapsedHeight * (_isExpanded ? 1.08 : 1.0),
                      margin: EdgeInsets.fromLTRB(
                          horizontalPadding, topMargin, horizontalPadding, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Hintergrund Blur (leicht reduziert)
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(color: Colors.transparent),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2.5,
                                ),
                              ),
                            ),
                            // Gecachtes Albumcover
                            CachedNetworkImage(
                              imageUrl: widget.track.albumImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _coverFallback(),
                              errorWidget: (_, __, ___) => _coverFallback(),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 3,
                                ),
                              ),
                            ),
                            // Player Bar
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
                                textColor: _textColor,
                                player: player,
                                textShadows: [
                                  Shadow(
                                    offset: const Offset(1.5, 1.5),
                                    blurRadius: 2,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                            // Track Details
                            Positioned(
                              bottom: 50,
                              left: 25,
                              right: 25,
                              child: IgnorePointer(
                                ignoring: !_isExpanded,
                                child: Opacity(
                                  opacity: _infoFadeAnim.value,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(Icons.album, "Album",
                                          widget.track.albumName),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(Icons.calendar_today,
                                          "Release", widget.track.releaseDate),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(Icons.trending_up,
                                          "Popularity",
                                          "${widget.track.popularity}%"),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _coverFallback() => Container(
        color: Colors.grey.shade900.withOpacity(0.5),
        child: const Center(
          child: Icon(Icons.music_note_rounded,
              size: 60, color: Colors.white38),
        ),
      );

  Widget _buildInfoRow(IconData icon, String label, String value) {
    const shadowOffset = Offset(1.5, 1.5);
    const shadowColor = Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Positioned(
              left: shadowOffset.dx,
              top: shadowOffset.dy,
              child: Icon(icon, color: shadowColor, size: 18),
            ),
            Icon(icon, color: _textColor, size: 18),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: GoogleFonts.manrope(
            color: _textColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            shadows: const [
              Shadow(
                offset: shadowOffset,
                blurRadius: 2,
                color: shadowColor,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              color: _textColor.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 16,
              shadows: const [
                Shadow(
                  offset: shadowOffset,
                  blurRadius: 2,
                  color: shadowColor,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
