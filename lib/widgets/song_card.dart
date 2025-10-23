import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:swipetune/API/SpotifyApiClient.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipetune/API/firebase_client.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';
import 'package:swipetune/services/discovery_service.dart';
import 'package:swipetune/utils/local_preferences_storage.dart';
import 'player_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class GlassSongCard extends StatefulWidget {
  final FirebaseTrack track;
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
  final Color _textColor = const Color.fromARGB(255, 255, 255, 255);

  late final AnimationController _controller;
  late final Animation<double> _liftAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _controlsFadeAnim;
  late Animation<double> _titleSlideAnim;
  late final Animation<double> _downShiftAnim;
  late final Animation<double> _infoFadeAnim;
  late final AudioPlayer player;
  late final DiscoveryService discoveryService;
  late final SpotifyApiClient apiclient;
  late final LocalPreferenceStorage localPreferenceStorage;
  late final FirebaseClient firebaseClient;

  @override
  void initState() {
    super.initState();
    localPreferenceStorage = LocalPreferenceStorage();
    apiclient = SpotifyApiClient();
    firebaseClient = FirebaseClient();
    discoveryService = DiscoveryService(this.firebaseClient, this.localPreferenceStorage, this.apiclient);
    
    player = AudioPlayer(
      audioLoadConfiguration: AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          minBufferDuration: const Duration(seconds: 5),
          maxBufferDuration: const Duration(seconds: 10),
          bufferForPlaybackDuration: const Duration(seconds: 2),
          prioritizeTimeOverSizeThresholds: true,
        ),
        darwinLoadControl: DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: const Duration(seconds: 5),
        ),
      ),
    );
    initPlayer();


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

  void _toggleExpand() 
  {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) 
      {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void initPlayer() async 
  {
    String? previewUrl = await discoveryService.getDeezerPreviewUrl(widget.track); 
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
    
    
    

    return LayoutBuilder(
      builder: (context, constraints) {
        final dynamicSlide = -constraints.maxHeight * 0.46;

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
                            // Hintergrund Blur
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSpotifyButton("https://open.spotify.com/track/${widget.track.id}"),
                                      const SizedBox(height: 10),
                                      _buildInfoRow(Icons.album, "Album", widget.track.albumName),
                                      const SizedBox(height: 10),
                                      _buildInfoRow(Icons.calendar_today, "Release", widget.track.releaseDate),
                                      const SizedBox(height: 10),
                                      _buildInfoRow(Icons.trending_up, "Popularity", "${widget.track.popularity}%"),
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
          child: Icon(Icons.music_note_rounded, size: 60, color: Colors.white38),
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
              child: Icon(icon, color: const Color.fromARGB(221, 0, 0, 0), size: 18),
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

  Widget _buildSpotifyButton(String? spotifyUrl) {
  if (spotifyUrl == null || spotifyUrl.isEmpty) return const SizedBox.shrink();

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      splashColor: const Color.fromARGB(60, 95, 221, 11),
      highlightColor: Colors.white10,
      onTap: () async {
        try {
          final uri = Uri.parse(spotifyUrl);
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!launched) {
            debugPrint("Could not launch Spotify URL in browser");
          }
        } catch (e) {
          debugPrint("Error launching Spotify URL: $e");
        }
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal:  3, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.spotify, color: Color.fromARGB(255, 50, 221, 7), size: 16),
            const SizedBox(width: 8),
            Text(
              "Listen on Spotify",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
