import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderScrollHandler extends StatefulWidget {
  final ScrollController scrollController;
  final ValueNotifier<int> currentPageNotifier;

  const HeaderScrollHandler({
    super.key,
    required this.scrollController,
    required this.currentPageNotifier,
  });

  @override
  State<HeaderScrollHandler> createState() => _HeaderScrollHandlerState();
}

class _HeaderScrollHandlerState extends State<HeaderScrollHandler> {
  static const double maxHeight = 80.0;
  static const double minHeight = 60.0; // Einführung einer minimalen Höhe für modernen Look
  double _currentHeight = maxHeight;

  final Map<int, String> pageTitles = {
    0: "SwipeTune",
    1: "Your Library",
    2: "Likes Page",
    3: "Settings"
  };

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final shrinkOffset = offset.clamp(0.0, maxHeight - minHeight);
    final newHeight = maxHeight - shrinkOffset;

    if (newHeight != _currentHeight) {
      setState(() {
        _currentHeight = newHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final title = pageTitles[widget.currentPageNotifier.value] ?? "SwipeTune";
    final progress = 1.0 - ((_currentHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);

    return Positioned(
      top: safeAreaTop + 16.0, // Position slightly below safe area
      left: 24.0,
      right: 24.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Smooth animation
        height: _currentHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8 * (1 - progress)), // Fade background on scroll
              Colors.transparent,
            ],
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: progress * 10,
              sigmaY: progress * 10,
            ),
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  // Logo mit animierter Größe
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 20 + 16 * (1 - progress), // Größe von 36 zu 20 skalieren
                    height: 20 + 16 * (1 - progress),
                    child: Icon(
                      Icons.waves_rounded,
                      color: Colors.white.withOpacity(0.9 + progress * 0.1), // Fade logo on scroll
                      size: 20 + 16 * (1 - progress),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title mit animierter Größe und Transparenz
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.currentPageNotifier,
                      builder: (context, page, child) {
                        final title = pageTitles[page] ?? "SwipeTune";
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
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
                          child: Text(
                            title,
                            key: ValueKey(title),
                            style: GoogleFonts.manrope(
                              fontSize: 20 - 4 * progress, // Größe von 20 zu 16 skalieren
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.9 - progress * 0.3), // Fade title on scroll
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
