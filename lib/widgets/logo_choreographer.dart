import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/widgets/auth_widgets.dart';

class LogoChoreographer extends StatefulWidget {
  final AnimationController introController;
  final AnimationController spotifyController;
  final AnimationController authController;
  final AnimationController homeController;
  final VoidCallback onCancelSpotify;
  final ValueNotifier<int> currentPageNotifier;
  final ScrollController? scrollController;

  const LogoChoreographer({
    super.key,
    required this.introController,
    required this.spotifyController,
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
      setState(() {
        _scrollOffset = widget.scrollController!.offset;
      });
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

    // --- Positional & Size Animations (Restored to original logic) ---
    final introY = Tween<double>(begin: size.height / 2 - 40, end: size.height * 0.25).animate(introCurve);
    final spotifyY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.35).animate(spotifyCurve);
    final authY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.15).animate(authCurve);

    // The final Y position is now consistent, preventing jumps.
    final homeY = Tween<double>(begin: size.height * 0.35, end: safeArea.top + 16).animate(homeCurve);

    final logoSize = Tween<double>(begin: 80.0, end: 60.0).animate(introCurve);
    final homeLogoSize = Tween<double>(begin: 60.0, end: 36.0).animate(homeCurve);

    final panelFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: widget.spotifyController, curve: const Interval(0.7, 1.0)));

    return AnimatedBuilder(
      animation: Listenable.merge([widget.introController, widget.spotifyController, widget.authController, widget.homeController, widget.currentPageNotifier]),
      builder: (context, child) {
        double y;
        double sizeValue;


        if (widget.homeController.value > 0) {
          y = homeY.value;
        } else if (widget.spotifyController.value > 0) {
          y = spotifyY.value;
        } else if (widget.authController.value > 0) {
          y = authY.value;
        } else {
          y = introY.value;
        }

        // Determine size based on the current app state
        sizeValue = widget.homeController.value > 0 ? homeLogoSize.value : logoSize.value;

        final isSpotifyVisible = widget.spotifyController.value > 0 && widget.homeController.value == 0;
        final isHomeVisible = widget.homeController.value > 0;

        return Stack(
          // Using ignorePointer to prevent interaction with invisible elements.
          children: [
            // --- The Single, Evolving Header ---
            Positioned(
              top: y,
              left: 0,
              right: 0,
              child: _buildEvolvingHeader(context, isSpotifyVisible, isHomeVisible, sizeValue, widget.currentPageNotifier.value),
            ),

            // --- Spotify Connecting Panel ---
            // Fades out smoothly as the home screen appears.
            Positioned(
              top: size.height * 0.35 + 120,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: widget.homeController.value > 0,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(widget.homeController),
                  child: FadeTransition(
                    opacity: panelFade,
                  child: SpotifyLoginPanel(onCancel: widget.onCancelSpotify),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // This single helper builds the correct header based on the app's state.
  Widget _buildEvolvingHeader(BuildContext context, bool isSpotify, bool isHome, double size, int currentPage) {
    if (isHome) {

      return _buildMorphingHomeHeader(size, currentPage);
    }

    // This part remains unchanged for the perfect intro/spotify animation
    Widget content;
    if (isSpotify) {
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
      content = Icon(Icons.waves_rounded, key: const ValueKey('intro-logo'), color: Colors.white, size: size);
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: content);
  }


 Widget _buildMorphingHomeHeader(double size, int currentPage) {

    const pageTitles = {
      0: "SwipeTune",

      1: "Your Library",
      2: "Likes Page",
      3: "Settings"
    };
    final title = pageTitles[currentPage];

    // Calculate scroll progress for effects (0.0 = no scroll, 1.0 = fully scrolled)
    final shrinkOffset = _scrollOffset.clamp(0.0, 40.0); // Smooth transition over 40 pixels
    final progress = (shrinkOffset / 40.0).clamp(0.0, 1.0);

    // Keep the header at full height, but add elegant effects when scrolling
    final currentHeight = size + 8;

    // Stable container with professional scroll effects
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Smoother transition
      height: currentHeight, // Keep full height for professional look
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRect( // Prevent overflow of blurred elements
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: progress * 15, // Stronger blur for elegance
            sigmaY: progress * 15,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(progress * 0.7), // Subtle background overlay
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
                  : [], // Professional shadow when scrolling
            ),
            child: Stack(
              children: [
                // Logo with subtle scale and opacity effect
                Positioned(
                  left: 24.0,
                  top: 4,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: 1.0 - (progress * 0.1), // Subtle fade
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: 1.0 + (progress * 0.05), // Slight upscale for elegance
                      child: Icon(
                        Icons.waves_rounded,
                        color: Colors.white,
                        size: size,
                      ),
                    ),
                  ),
                ),
                // Title with enhanced styling when scrolling
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
                                    : [], // Text shadow when scrolling
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
