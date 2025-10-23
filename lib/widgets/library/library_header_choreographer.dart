import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dedicated choreographer for Library screen header animations
/// Handles smooth morphing between "Your Library" and detail view back button
class LibraryHeaderChoreographer extends StatelessWidget {
  final AnimationController detailMorphController;
  final ValueNotifier<bool> isDetailViewNotifier;
  final ScrollController? scrollController;

  const LibraryHeaderChoreographer({
    super.key,
    required this.detailMorphController,
    required this.isDetailViewNotifier,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return AnimatedBuilder(
      animation: Listenable.merge([
        detailMorphController,
        isDetailViewNotifier,
      ]),
      builder: (context, child) {
        final isDetailView = isDetailViewNotifier.value;
        final morphProgress = detailMorphController.value;
        
        // Smooth position transitions
        final headerHeight = 44.0;
        final topPosition = safeArea.top + 16.0;
        
        // Text fades out while logo stays
        final textOpacity = 1.0 - morphProgress;
        final logoLeft = 24.0;
        
        return Positioned(
          top: topPosition,
          left: 0,
          right: 0,
          height: headerHeight,
          child: IgnorePointer(
            ignoring: isDetailView,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: isDetailView ? 0.0 : 1.0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: morphProgress * 15,
                    sigmaY: morphProgress * 15,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(morphProgress * 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Logo - always visible
                        Positioned(
                          left: logoLeft,
                          top: 4,
                          child: Icon(
                            Icons.waves_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        
                        // "Your Library" Text - fades out smoothly
                        Positioned(
                          left: logoLeft + 36.0 + 12.0,
                          top: 0,
                          bottom: 0,
                          right: 24.0,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            opacity: textOpacity,
                            child: AnimatedSlide(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              offset: Offset(morphProgress * -0.1, 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Your Library',
                                  style: GoogleFonts.manrope(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
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
            ),
          ),
        );
      },
    );
  }
}

class AnimatedSlide extends ImplicitlyAnimatedWidget {
  final Widget child;
  final Offset offset;

  const AnimatedSlide({
    super.key,
    required this.child,
    required this.offset,
    required super.duration,
    super.curve,
  });

  @override
  AnimatedWidgetBaseState<AnimatedSlide> createState() => _AnimatedSlideState();
}

class _AnimatedSlideState extends AnimatedWidgetBaseState<AnimatedSlide> {
  Tween<Offset>? _offset;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _offset = visitor(
      _offset,
      widget.offset,
      (dynamic value) => Tween<Offset>(begin: value as Offset),
    ) as Tween<Offset>?;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        _offset!.evaluate(animation).dx * 100,
        _offset!.evaluate(animation).dy * 100,
      ),
      child: widget.child,
    );
  }
}
