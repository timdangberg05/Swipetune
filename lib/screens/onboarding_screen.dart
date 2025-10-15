import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/widgets/action_buttons.dart';

class OnboardingScreen extends StatefulWidget {
  final AnimationController backgroundMorphController;
  final VoidCallback onComplete;
  final String? userName;

  const OnboardingScreen({
    super.key,
    required this.backgroundMorphController,
    required this.onComplete,
    this.userName,
  });

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  double _pageOffset = 0.0;

  late final List<Map<String, dynamic>> onboardingSteps;

  @override
  void initState() {
    super.initState();
    // KORRIGIERT: Liste wird hier initialisiert, um auf widget.userName zugreifen zu können
    onboardingSteps = [
      {'symbol': AnimatedSymbol.welcome, 'title': 'Welcome, ${widget.userName ?? 'Pioneer'}', 'description': 'Your personalized music journey begins now.'},
      {'symbol': AnimatedSymbol.swipeRight, 'title': 'Swipe to Discover', 'description': 'A right swipe adds the track to your future playlist.'},
      {'symbol': AnimatedSymbol.swipeLeft, 'title': 'Swipe to Skip', 'description': 'A left swipe fine-tunes your taste with every move.'},
      {'symbol': AnimatedSymbol.playlist, 'title': 'Build Your Identity', 'description': 'Your swipes automatically forge playlists in your library.'},
    ];

    widget.backgroundMorphController.forward();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        HapticFeedback.lightImpact();
      }
      setState(() {
        _currentPage = newPage;
        _pageOffset = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    widget.backgroundMorphController.reverse();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // KORRIGIERT: Kein Scaffold mehr, damit der BackdropFilter den Hintergrund durchlässt
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: onboardingSteps.length,
          itemBuilder: (context, index) {
            final step = onboardingSteps[index];
            final double distortion = (_pageOffset - index);
            
            return _buildOnboardingPage(
              symbol: step['symbol'],
              title: step['title'],
              description: step['description'],
              distortion: distortion,
            );
          },
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 40,
          left: 24,
          right: 24,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(onboardingSteps.length, (i) => _buildDot(i)),
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentPage == onboardingSteps.length - 1
                    ? ActionButton(
                        key: const ValueKey('onboarding_btn'),
                        accentColor: const Color(0xFF9B51E0),
                        text: "Enter Swipetune",
                        onTap: widget.onComplete,
                      )
                    : const SizedBox(key: ValueKey('placeholder'), height: 56),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildOnboardingPage({required AnimatedSymbol symbol, required String title, required String description, required double distortion}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NextLevelGlassCard(
          distortion: distortion,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSymbolPainter(symbol: symbol, key: ValueKey(symbol)),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 16, color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NextLevelGlassCard extends StatefulWidget {
  final Widget child;
  final double distortion;
  const NextLevelGlassCard({super.key, required this.child, required this.distortion});

  @override
  _NextLevelGlassCardState createState() => _NextLevelGlassCardState();
}

class _NextLevelGlassCardState extends State<NextLevelGlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final angle = _shimmerController.value * 2 * math.pi;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(widget.distortion * -0.2)
            ..scale(1 - widget.distortion.abs() * 0.1),
          alignment: FractionalOffset.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                   gradient: LinearGradient(
                    transform: GradientRotation(angle),
                    colors: [
                      const Color(0xFF9B51E0).withOpacity(0.3),
                      Colors.transparent,
                      const Color(0xFF2D9CDB).withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

enum AnimatedSymbol { welcome, swipeRight, swipeLeft, playlist }

class AnimatedSymbolPainter extends StatefulWidget {
  final AnimatedSymbol symbol;
  const AnimatedSymbolPainter({super.key, required this.symbol});

  @override
  _AnimatedSymbolPainterState createState() => _AnimatedSymbolPainterState();
}

class _AnimatedSymbolPainterState extends State<AnimatedSymbolPainter> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1))
      ..addListener(() {
        setState(() {});
      })
      ..repeat(); // KORRIGIERT: Animation läuft jetzt kontinuierlich
    _initParticles();
  }

  void _initParticles() {
    particles = List.generate(120, (index) => Particle(
      position: Offset(40 + (_random.nextDouble() - 0.5) * 120, 30 + (_random.nextDouble() - 0.5) * 120),
      target: _getTargetForIndex(index),
      size: _random.nextDouble() * 2 + 1.5,
      color: [const Color(0xFF9B51E0), const Color(0xFF2D9CDB), const Color(0xFFF271B6)].elementAt(_random.nextInt(3)),
      velocity: Offset.zero
    ));
  }
  
  Offset _getTargetForIndex(int index) {
     final i = index.toDouble();
     switch(widget.symbol) {
      case AnimatedSymbol.welcome:
        final angle = i / 120 * math.pi * 4;
        return Offset(40 + math.cos(angle) * (25 + math.sin(angle*3)*5), 30 + math.sin(angle) * (25+math.cos(angle*3)*5));
      case AnimatedSymbol.swipeRight:
        if (i < 80) return Offset(10 + (i/80)*50, 30);
        final p = (i - 80) / 40;
        if (p < 0.5) return Offset(60 - p * 2 * 15, 30 - p * 2 * 15);
        return Offset(60 - (1-p) * 2 * 15, 30 + (1-p) * 2 * 15);
      case AnimatedSymbol.swipeLeft:
        if (i < 80) return Offset(70 - (i/80)*50, 30);
        final p = (i - 80) / 40;
        if (p < 0.5) return Offset(20 + p * 2 * 15, 30 - p * 2 * 15);
        return Offset(20 + (1-p) * 2 * 15, 30 + (1-p) * 2 * 15);
      case AnimatedSymbol.playlist:
        return Offset(15 + (i % 30) * 2.0, 15 + (i ~/ 30) * 10.0);
     }
  }

  @override
  void didUpdateWidget(covariant AnimatedSymbolPainter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.symbol != widget.symbol) {
       for(int i = 0; i < particles.length; i++) {
         particles[i].target = _getTargetForIndex(i);
       }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 60),
      painter: _SymbolParticlePainter(particles: particles),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  Offset target;
  double size;
  Color color;
  Particle({required this.position, required this.target, required this.size, required this.color, required this.velocity});

  void update() {
    final acceleration = (target - position) * 0.02;
    velocity += acceleration;
    velocity *= 0.85; // Dämpfung für einen weichen, organischen Look
    position += velocity;
  }
}

class _SymbolParticlePainter extends CustomPainter {
  final List<Particle> particles;
  _SymbolParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for(var p in particles) {
      p.update();
      final paint = Paint()..color = p.color;
      paint.imageFilter = ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5);
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SymbolParticlePainter oldDelegate) => true;
}

