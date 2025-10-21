import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/widgets/auth_widgets.dart';

class LogoChoreographer extends StatelessWidget {
  final AnimationController introController;
  final AnimationController spotifyController;
  final AnimationController authController;
  final AnimationController homeController;
  final VoidCallback onCancelSpotify;
  final ValueNotifier<int> currentPageNotifier;

  const LogoChoreographer({
    super.key,
    required this.introController,
    required this.spotifyController,
    required this.authController,
    required this.homeController,
    required this.onCancelSpotify,
    required this.currentPageNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // --- Base Animation Curves ---
    final introCurve = CurvedAnimation(parent: introController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic));
    final spotifyCurve = CurvedAnimation(parent: spotifyController, curve: const Interval(0.2, 0.8, curve: Curves.easeInOutCubic));
    final authCurve = CurvedAnimation(parent: authController, curve: Curves.easeInOutCubic);
    final homeCurve = CurvedAnimation(parent: homeController, curve: Curves.easeInOutCubic);

    // --- Positional & Size Animations (Restored to original logic) ---
    final introY = Tween<double>(begin: size.height / 2 - 40, end: size.height * 0.25).animate(introCurve);
    final spotifyY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.35).animate(spotifyCurve);
    final authY = Tween<double>(begin: size.height * 0.25, end: size.height * 0.15).animate(authCurve);
    
    // The final Y position is now consistent, preventing jumps.
    final homeY = Tween<double>(begin: size.height * 0.35, end: safeArea.top + 16).animate(homeCurve);

    final logoSize = Tween<double>(begin: 80.0, end: 60.0).animate(introCurve);
    final homeLogoSize = Tween<double>(begin: 60.0, end: 36.0).animate(homeCurve);

    final panelFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: spotifyController, curve: const Interval(0.7, 1.0)));

    return AnimatedBuilder(
      animation: Listenable.merge([introController, spotifyController, authController, homeController, currentPageNotifier]),
      builder: (context, child) {
        double y;
        double sizeValue;

     
        if (homeController.value > 0) {
          y = homeY.value;
        } else if (spotifyController.value > 0) {
          y = spotifyY.value;
        } else if (authController.value > 0) {
          y = authY.value;
        } else {
          y = introY.value;
        }

        // Determine size based on the current app state
        sizeValue = homeController.value > 0 ? homeLogoSize.value : logoSize.value;

        final isSpotifyVisible = spotifyController.value > 0 && homeController.value == 0;
        final isHomeVisible = homeController.value > 0;

        return Stack(
          // Using ignorePointer to prevent interaction with invisible elements.
          children: [
            // --- The Single, Evolving Header ---
            Positioned(
              top: y,
              left: 0,
              right: 0,
              child: _buildEvolvingHeader(context, isSpotifyVisible, isHomeVisible, sizeValue, currentPageNotifier.value),
            ),

            // --- Spotify Connecting Panel ---
            // Fades out smoothly as the home screen appears.
            Positioned(
              top: size.height * 0.35 + 120,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: homeController.value > 0,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(homeController),
                  child: FadeTransition(
                    opacity: panelFade,
                    child: SpotifyLoginPanel(onCancel: onCancelSpotify),
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
      final xFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: spotifyController, curve: const Interval(0.4, 0.9)));
      final swipetuneMoveX = Tween<double>(begin: 0, end: -40).animate(spotifyController);
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
    const pageTitles = {1: "Likes", 2: "Settings"};
    final title = pageTitles[currentPage];

    // Stable container with proper padding to prevent clipping
    return Container(
      height: size + 8, // Extra padding to prevent text clipping at bottom
      padding: const EdgeInsets.only(bottom: 4), // Prevents bottom clipping
      child: Stack(
        children: [
          // Logo positioned with perfect vertical centering
          Positioned(
            left: 24.0,
            top: 4,
            child: Icon(Icons.waves_rounded, color: Colors.white, size: size),
          ),
          // Title container with perfect alignment
          Positioned(
            left: 24.0 + size + 12.0,
            top: 0,
            bottom: 0,
            right: 24.0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeInOutCubicEmphasized,
              switchOutCurve: Curves.easeInOutCubicEmphasized,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                // Smoother, more refined animation curves
                final smoothCurve = CurveTween(curve: Curves.easeInOutCubicEmphasized);
                final curvedAnimation = animation.drive(smoothCurve);
                
                // Determine if this is entering or exiting
                final isEntering = child.key == ValueKey(title);
                
                if (isEntering) {
                  // Entering: slide from right with fade
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.15, 0),
                      end: Offset.zero,
                    ).animate(curvedAnimation),
                    child: FadeTransition(
                      opacity: curvedAnimation,
                      child: child,
                    ),
                  );
                } else {
                  // Exiting: slide to left with fade
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset.zero,
                      end: const Offset(-0.15, 0),
                    ).animate(curvedAnimation),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(curvedAnimation),
                      child: child,
                    ),
                  );
                }
              },
              child: title != null
                  ? Align(
                      key: ValueKey(title),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: size * 0.95, // Slightly smaller to ensure no clipping
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1, // Tight line height for better vertical centering
                        ),
                      ),
                    )
                  : Container(key: const ValueKey('no-title')),
            ),
          ),
        ],
      ),
    );
  }
}
