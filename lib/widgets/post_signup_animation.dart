import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostSignupAnimation extends StatefulWidget {
  final String userName;
  final VoidCallback onComplete;
  final AnimationController controller;

  const PostSignupAnimation({
    super.key,
    required this.userName,
    required this.onComplete,
    required this.controller,
  });

  @override
  _PostSignupAnimationState createState() => _PostSignupAnimationState();
}

class _PostSignupAnimationState extends State<PostSignupAnimation> {
  late Animation<double> _bubbleSize;
  late Animation<double> _textFade;
  late Animation<double> _revealRadius;

  @override
  void initState() {
    super.initState();

    _bubbleSize = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: widget.controller, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: widget.controller, curve: const Interval(0.3, 0.6, curve: Curves.easeIn)),
    );
    _revealRadius = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: widget.controller, curve: const Interval(0.7, 1.0, curve: Curves.easeIn)),
    );

    widget.controller.forward();
    widget.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: _revealRadius.value,
            center: size.center(Offset.zero),
            maxRadius: maxRadius,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Liquid Bubble
              Transform.scale(
                scale: _bubbleSize.value,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9B51E0).withOpacity(0.5),
                        const Color(0xFF2D9CDB).withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // Begrüßungstext
              FadeTransition(
                opacity: _textFade,
                child: Text(
                  "Hey, ${widget.userName}!",
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      const Shadow(blurRadius: 10, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;
  final double maxRadius;

  CircularRevealClipper({required this.fraction, required this.center, required this.maxRadius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: maxRadius * fraction));
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
