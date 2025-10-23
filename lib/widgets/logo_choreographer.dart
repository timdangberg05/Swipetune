import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/widgets/auth_widgets.dart';

class LogoChoreographer extends StatefulWidget {
  final AnimationController introController;
  final AnimationController spotifyController;
  final AnimationController spotifySuccessController; // NEU
  final AnimationController authController;
  final AnimationController homeController;
  final VoidCallback onCancelSpotify;
  final ValueNotifier<int> currentPageNotifier;
  final ScrollController? scrollController;

  const LogoChoreographer({
    super.key,
    required this.introController,
    required this.spotifyController,
    required this.spotifySuccessController, // NEU
    required this.authController,
    required this.homeController,
    required this.onCancelSpotify,
    required this.currentPageNotifier,
    this.scrollController,
  });

  @override
  State<LogoChoreographer> createState() => _LogoChoreographerState();
}

class _LogoChoreographerState extends State<LogoChoreographer> {
  double _scrollOffset = 0.0;
  static const double maxHeight = 44.0;
  static const double minHeight = 30.0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController != null && mounted) {

      // NEUE PRÜFUNG:
      final position = widget.scrollController!.position;
      if (position.maxScrollExtent > 0) {
        // Nur scrollen, wenn es Inhalt zum Scrollen gibt
        setState(() {
          _scrollOffset = position.pixels;
        });
      } else {
        // Wenn nicht scrollbar, Header in den "ungescrollten" Zustand zurücksetzen
        if (_scrollOffset != 0.0) {
          setState(() {
            _scrollOffset = 0.0;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // --- Base Animation Curves ---
    final introCurve = CurvedAnimation(parent: widget.introController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic));
    final spotifyCurve = CurvedAnimation(parent: widget.spotifyController, curve: const Interval(0.2, 0.8, curve: Curves.easeInOutCubic));
    final authCurve = CurvedAnimation(parent: widget.authController, curve: Curves.easeInOutCubic);
    final homeCurve = CurvedAnimation(parent: widget.homeController, curve: Curves.easeInOutCubic);

    // --- Positional & Size Animations ---
    final introY = Tween<double>(begin: size.height / 2 - 40, end: size.height * 0.25).animate(introCurve);
    final spotifyY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.35).animate(spotifyCurve);
    final authY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.15).animate(authCurve);
    final homeY = Tween<double>(begin: size.height * 0.35, end: safeArea.top + 16).animate(homeCurve);

    final logoSize = Tween<double>(begin: 80.0, end: 60.0).animate(introCurve);
    final homeLogoSize = Tween<double>(begin: 60.0, end: 36.0).animate(homeCurve);

    final panelFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: widget.spotifyController, curve: const Interval(0.7, 1.0)));

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.introController,
        widget.spotifyController,
        widget.authController,
        widget.homeController,
        widget.currentPageNotifier,
        widget.spotifySuccessController // NEU
      ]),
      builder: (context, child) {
        double y;
        double sizeValue;

        if (widget.homeController.value > 0) {
          y = homeY.value;
        } else if (widget.spotifyController.value > 0) { // Bleibt auf der Spotify-Y-Position
          y = spotifyY.value;
        } else if (widget.authController.value > 0) {
          y = authY.value;
        } else {
          y = introY.value;
        }

        sizeValue = widget.homeController.value > 0 ? homeLogoSize.value : logoSize.value;

        // --- NEUE STATE-LOGIK ---
        final isHomeVisible = widget.homeController.value > 0;
        // Zeigt Haken-Animation, wenn successController läuft
        final isSpotifySuccess = widget.spotifySuccessController.value > 0 && !isHomeVisible;
        // Zeigt "Connecting"-Logo, wenn spotifyController läuft, aber Haken-Anim noch nicht
        final isSpotifyConnecting = widget.spotifyController.value > 0 && !isSpotifySuccess && !isHomeVisible;
        // --- ENDE NEUE STATE-LOGIK ---

        return Stack(
          children: [
            Positioned(
              top: y,
              left: 0,
              right: 0,
              child: _buildEvolvingHeader(
                context,
                isSpotifyConnecting,
                isSpotifySuccess, // NEU
                isHomeVisible,
                sizeValue,
                widget.currentPageNotifier.value,
              ),
            ),

            // --- Spotify Connecting Panel ---
            Positioned(
              top: size.height * 0.35 + 120,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: widget.homeController.value > 0 || widget.spotifySuccessController.value > 0,
                child: FadeTransition(
                  // Fadet aus, wenn Home-Anim startet
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(widget.homeController),
                  child: FadeTransition(
                    // Fadet auch aus, wenn Haken-Anim startet
                    opacity: Tween<double>(begin: 1.0, end: 0.0).animate(widget.spotifySuccessController),
                    child: FadeTransition(
                      opacity: panelFade,
                      child: SpotifyLoginPanel(onCancel: widget.onCancelSpotify),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- NEUE FUNKTION: Baut die Haken-Animation ---
  Widget _buildSuccessCheckmark(double baseSize) {
    final anim = CurvedAnimation(parent: widget.spotifySuccessController, curve: Curves.easeInOutCubic);
    
    // 0.0s - 0.8s: Logos bewegen sich zur Mitte
    final mergeTween = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: anim, curve: const Interval(0.0, 0.4, curve: Curves.easeInOutCubic))
    );
    
    // 0.3s - 0.6s: Logos blenden aus
    final logoFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: anim, curve: const Interval(0.15, 0.3, curve: Curves.easeOut))
    );
    
    // 0.6s - 1.4s: Haken skaliert "elastisch" rein
    final checkScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: anim, curve: const Interval(0.3, 0.7, curve: Curves.elasticOut))
    );
    
    // 0.6s - 1.0s: Haken blendet ein
    final checkFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: anim, curve: const Interval(0.3, 0.5, curve: Curves.easeIn))
    );

    return Stack(
      key: const ValueKey('success-anim'),
      alignment: Alignment.center,
      children: [
        // Die zwei Logos, die verschmelzen
        FadeTransition(
          opacity: logoFadeOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-mergeTween.value, 0),
                child: Icon(Icons.waves_rounded, color: Colors.white, size: baseSize),
              ),
              Transform.translate(
                offset: Offset(mergeTween.value, 0),
                child: FaIcon(FontAwesomeIcons.spotify, color: const Color(0xFF1DB945), size: baseSize),
              ),
            ],
          ),
        ),
        
        // Der Haken, der erscheint
        FadeTransition(
          opacity: checkFadeIn,
          child: ScaleTransition(
            scale: checkScale,
            child: Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF1DB954), // Spotify-Grün für Erfolg
              size: baseSize * 1.2, // Etwas größer
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5)
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
  // --- ENDE NEUE FUNKTION ---


  Widget _buildEvolvingHeader(BuildContext context, bool isSpotifyConnecting, bool isSpotifySuccess, bool isHome, double size, int currentPage) {
    if (isHome) {
      return _buildMorphingHomeHeader(size, currentPage);
    }

    Widget content;
    
    if (isSpotifySuccess) {
      // NEU: Zeige die Haken-Animation
      content = _buildSuccessCheckmark(size);
    } else if (isSpotifyConnecting) {
      // Unverändert: "Connecting"-Animation
      final xFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: widget.spotifyController, curve: const Interval(0.4, 0.9)));
      final swipetuneMoveX = Tween<double>(begin: 0, end: -40).animate(widget.spotifyController);
      content = Row(
        key: const ValueKey('spotify-connect'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(offset: Offset(swipetuneMoveX.value, 0), child: Icon(Icons.waves_rounded, color: Colors.white, size: size)),
          FadeTransition(opacity: xFade, child: const Icon(Icons.close_rounded, color: Colors.white54, size: 30)),
          Transform.translate(offset: Offset(-swipetuneMoveX.value, 0), child: FaIcon(FontAwesomeIcons.spotify, color: const Color(0xFF1DB945), size: size)),
        ],
      );
    } else {
      // Unverändert: Intro-Logo
      content = Icon(Icons.waves_rounded, key: const ValueKey('intro-logo'), color: Colors.white, size: size);
    }
    
    // AnimatedSwitcher sorgt für den nahtlosen Übergang zwischen den Zuständen
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: content
    );
  }


  Widget _buildMorphingHomeHeader(double size, int currentPage) {
    const pageTitles = {
      0: "SwipeTune",
      1: "Your Library",
      2: "Likes Page",
      3: "Settings"
    };
    final title = pageTitles[currentPage];
    final shrinkOffset = _scrollOffset.clamp(0.0, 40.0);
    final progress = (shrinkOffset / 40.0).clamp(0.0, 1.0);
    final currentHeight = size + 8;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: currentHeight,
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: progress * 15,
            sigmaY: progress * 15,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(progress * 0.7),
                  Colors.transparent,
                ],
              ),
              boxShadow: progress > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(progress * 0.3),
                        blurRadius: progress * 20,
                        spreadRadius: progress * 5,
                        offset: Offset(0, progress * 10),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 24.0,
                  top: 4,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: 1.0 - (progress * 0.1),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: 1.0 + (progress * 0.05),
                      child: Icon(
                        Icons.waves_rounded,
                        color: Colors.white,
                        size: size,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24.0 + size + 12.0,
                  top: 0,
                  bottom: 0,
                  right: 24.0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: title != null
                        ? Align(
                            key: ValueKey(title),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: GoogleFonts.manrope(
                                fontSize: size * 0.95,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                                shadows: progress > 0
                                    ? [
                                        Shadow(
                                          color: Colors.black.withOpacity(progress * 0.5),
                                          blurRadius: progress * 10,
                                          offset: Offset(0, progress * 3),
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                          )
                        : const SizedBox(key: ValueKey('no-title')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
