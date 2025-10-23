import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipetune/models/blob.dart'; // Stelle sicher, dass dieser Import korrekt ist
import '../providers/spotify_data_provider.dart'; // Stelle sicher, dass dieser Import korrekt ist

// enum SwipeAction { like, dislike }

extension OffsetExtensions on Offset {
  Offset normalized() {
    final d = distance;
    if (d == 0) return Offset.zero;
    return this / d;
  }
}

class LiquidGlassBackground extends StatefulWidget {
  final Animation<double> time;
  final Animation<double> colorTransitionValue;
  final ValueNotifier<Offset?> spotifyLogoCenterNotifier;
  final ValueNotifier<SwipeAction?>? swipeActionNotifier;
  final AnimationController? backgroundMorphController;
  final Animation<double>? homeTransitionController;
  final Animation<double>? libraryMorphAnimation; // NEU

  const LiquidGlassBackground({
    super.key,
    required this.time,
    required this.colorTransitionValue,
    required this.spotifyLogoCenterNotifier,
    this.swipeActionNotifier,
    this.backgroundMorphController,
    this.homeTransitionController,
    this.libraryMorphAnimation,
  });

  @override
  State<LiquidGlassBackground> createState() => _LiquidGlassBackgroundState();
}

class _LiquidGlassBackgroundState extends State<LiquidGlassBackground> with TickerProviderStateMixin {
  late final List<Blob> _blobs;
  final List<Color> _originalColors = [];
  final List<double> _originalRadii = [];
  
  late AnimationController _swipeFeedbackController;
  SwipeAction? _lastProcessedAction;
  double _lastGlowValue = 0.0; // Neue Variable für nahtlose Glow-Animation

  // --- NEU: Status-Variablen für Farb-Latching ---
  // Definiere die Farben hier, damit wir sie speichern können
  final Color _likeColor = const Color(0xFF1DB954);
  final Color _dislikeColor = const Color(0xFFC73666);
  // Diese Variable "merkt" sich die Farbe für die Dauer der Animation
  Color _activeFeedbackColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
      _blobs = List.generate(4, (index) {
      final rand = math.Random();
      final color = Color.lerp(const Color(0xFF9B51E0).withOpacity(0.7), const Color(0xFF2D9CDB).withOpacity(0.7), rand.nextDouble())!;
      final radius = rand.nextDouble() * 0.15 + 0.25; // Größere Start-Radien
      _originalColors.add(color);
      _originalRadii.add(radius);
      return Blob(
        position: Offset(rand.nextDouble(), rand.nextDouble()),
        radius: radius,
        velocity: Offset(rand.nextDouble() * 0.1 - 0.05, rand.nextDouble() * 0.1 - 0.05),
        color: color,
      );
    });

    _swipeFeedbackController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _swipeFeedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpotifyDataProvider>();
    
    final allListenables = [
      widget.time,
      widget.colorTransitionValue,
      widget.spotifyLogoCenterNotifier,
      _swipeFeedbackController,
      if (widget.backgroundMorphController != null) widget.backgroundMorphController,
      if (widget.homeTransitionController != null) widget.homeTransitionController,
      if (widget.libraryMorphAnimation != null) widget.libraryMorphAnimation,
      if (widget.swipeActionNotifier != null) widget.swipeActionNotifier,
      provider.swipeProgressNotifier,
    ].where((l) => l != null).cast<Listenable>().toList();

    return AnimatedBuilder(
      animation: Listenable.merge(allListenables),
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final logoCenter = widget.spotifyLogoCenterNotifier.value;
        const repulsionRadius = 90.0;
        final morphValue = widget.backgroundMorphController?.value ?? 0.0;
        final homeTransition = widget.homeTransitionController?.value ?? 0.0;
        final libraryMorph = widget.libraryMorphAnimation?.value ?? 0.0; // NEU

        // WICHTIG: Die effektive "unten"-Position.
        // homeTransition (1.0) - libraryMorph (0.0) = 1.0 (Blobs sind unten)
        // homeTransition (1.0) - libraryMorph (1.0) = 0.0 (Blobs sind oben/frei)
        final double effectiveHomeTransition = (homeTransition - libraryMorph).clamp(0.0, 1.0);
        
        final dragInfluence = provider.swipeProgressNotifier.value;
        final double likeGlow = (dragInfluence).clamp(0.0, 1.0);
        final double dislikeGlow = (-dragInfluence).clamp(0.0, 1.0);
        final double currentGlow = math.max(likeGlow, dislikeGlow);


        // --- NEUE, VEREINHEITLICHTE GLOW/FLASH LOGIK (Version 3) ---
        final currentAction = widget.swipeActionNotifier?.value;

        // 1. Ein neuer Swipe wurde *bestätigt* (losgelassen)
        if (currentAction != null && currentAction != _lastProcessedAction) {
          _lastProcessedAction = currentAction;

          // SETZE DIE "LATCHED" FARBE
          _activeFeedbackColor = (currentAction == SwipeAction.like) ? _likeColor : _dislikeColor;

          _swipeFeedbackController.forward(from: _lastGlowValue);

          void listener(status) { // 'listener' muss hier definiert werden, um entfernt zu werden
            if (status == AnimationStatus.completed) {
              _swipeFeedbackController.removeStatusListener(listener);
            }
          }
          _swipeFeedbackController.addStatusListener(listener);

        // 2. Der Swipe-Status wurde vom Provider zurückgesetzt (Flash-Animation soll abklingen)
        } else if (currentAction == null && _lastProcessedAction != null) {
          _lastProcessedAction = null;
          _swipeFeedbackController.reverse(); // Fade den Flash/Glow aus
          // _activeFeedbackColor bleibt auf der letzten Farbe, während es ausfadet!

        // 3. Wir *ziehen* gerade (kein bestätigter Swipe)
        } else if (_lastProcessedAction == null) {
          _swipeFeedbackController.value = currentGlow;

          // SETZE DIE "LATCHED" FARBE AUCH WÄHREND DES ZIEHENS
          if (likeGlow > 0) {
            _activeFeedbackColor = _likeColor;
          } else if (dislikeGlow > 0) {
            _activeFeedbackColor = _dislikeColor;
          }
        }

        if (currentGlow > 0) {
          _lastGlowValue = currentGlow;
        }
        // --- ENDE NEUE LOGIK ---

        final List<Color> _spotifyColors = [
          const Color(0xFF1DB954).withOpacity(0.6), const Color(0xFF1ED760).withOpacity(0.5),
          const Color(0xFF4AE280).withOpacity(0.5), const Color(0xFF2DEB70).withOpacity(0.4),
        ];

        // Definiere die Zielfarben.
        final likeColor = const Color(0xFF1DB954); // Spotify-Grün
        final dislikeColor = const Color(0xFFC73666); // Ein Rotton

        // Der feedbackColor wird jetzt vom Controller UND der gelatchten Farbe gesteuert
        final feedbackColor = ColorTween(
          begin: Colors.transparent, // Immer von transparent...
          end: _activeFeedbackColor,   // ...zur aktiven Farbe
        ).transform(_swipeFeedbackController.value);

        for (int i = 0; i < _blobs.length; i++) {
          final blob = _blobs[i];
          
          // ### LOGIK FÜR HOME-SCREEN (NACH DEM LOGIN) ###
          if (effectiveHomeTransition > 0.0) {
            // 1. ZIELPOSITION AM UNTEREN RAND (DIE "FALL-ANIMATION")
            final navBarY = size.height - 55 - (MediaQuery.of(context).padding.bottom);
            final targetPosition = Offset(
              (size.width / (_blobs.length + 1)) * (i + 1),
              navBarY + (math.sin(i + widget.time.value * 2 * (i + 1)) * 15),
            );
            final currentPixelPosition = Offset(blob.position.dx * size.width, blob.position.dy * size.height);
            // Bubbles "fallen" an ihre Position
            final lerpedPosition = Offset.lerp(currentPixelPosition, targetPosition, 0.05)!;
            
            // 2. GESCHWINDIGKEIT DÄMPFEN, WÄHREND SIE "FALLEN"
            blob.velocity *= (1 - effectiveHomeTransition * 0.2);
            var newVelocity = blob.velocity;

            // 3. HORIZONTAL DRAG FOLLOW (Reagiert auf Karten-Swipe)
            if (dragInfluence.abs() > 0.01) {
                // HIER: Multiplikator von 0.5 auf 0.25 reduziert
                final horizontalPull = dragInfluence * 0.25;
                newVelocity += Offset(horizontalPull, 0);
                // HIER: Diese Zeile hat den Effekt übertrieben und wird entfernt/auskommentiert
                // newVelocity += Offset(horizontalPull * (blob.position.dx - 0.5).abs() * 0.8, 0);
                
                newVelocity += Offset(0, math.sin(blob.position.dx * math.pi * 2) * horizontalPull * 0.2);
                blob.radius += dragInfluence.abs() * 0.003; 
            }

            // 4. NEUE POSITION BERECHNEN (Kombiniert "Falen" und "Swipe")
            // Wir nehmen die "gefallene" Position und addieren die (gedämpfte) Swipe-Geschwindigkeit
            var newPosition = Offset(lerpedPosition.dx / size.width, lerpedPosition.dy / size.height) + newVelocity * 0.02;

            // 5. Radius zurückfedern
            if (blob.radius > _originalRadii[i] + 0.1) {
                blob.radius *= 0.96;
            }
            
            // 6. Randprüfung (Wrap-Around für Swipes)
            if (newPosition.dx > 1.2) newPosition = Offset(-0.2, newPosition.dy);
            if (newPosition.dx < -0.2) newPosition = Offset(1.2, newPosition.dy);
            // Vertikales Wrap-Around ist hier nicht nötig, da sie am Boden "kleben"

            blob.position = newPosition;
            // HIER: Neue Dämpfungszeile für sanftere Bewegung
            blob.velocity = newVelocity * 0.95; // Dämpft die Geschwindigkeit leicht ab
          
          // ### LOGIK FÜR LOGIN-SCREEN (RANDOM BEWEGUNG) ###
          } else {
            // Dies ist die Logik aus deiner "alten" Version, die funktioniert hat
            blob.position += blob.velocity * 0.015; // Keine Dämpfung
            
            if (logoCenter != null) {
              final blobPixelPosition = Offset(blob.position.dx * size.width, blob.position.dy * size.height);
              final distanceVector = blobPixelPosition - logoCenter;
              if (distanceVector.distance < repulsionRadius && distanceVector.distance > 0.1) {
                final normal = distanceVector.normalized();
                final dot = blob.velocity.dx * normal.dx + blob.velocity.dy * normal.dy;
                blob.velocity = blob.velocity - (normal * (2 * dot));
                blob.position += normal * 0.03;
              }
            }

            // Randprüfung (Wrap-Around)
            if (blob.position.dx > 1.2) blob.position = Offset(-0.2, blob.position.dy);
            if (blob.position.dx < -0.2) blob.position = Offset(1.2, blob.position.dy);
            if (blob.position.dy > 1.2) blob.position = Offset(blob.position.dx, -0.2);
            if (blob.position.dy < -0.2) blob.position = Offset(blob.position.dx, 1.2);
          }

          // --- VEREINFACHTE FARB-LOGIK in der for-Schleife (Version 3) ---
          final spotifyBlendedColor = Color.lerp(_originalColors[i], _spotifyColors[i % _spotifyColors.length], widget.colorTransitionValue.value)!;
          Color finalColor = spotifyBlendedColor;

          if (feedbackColor != null && _swipeFeedbackController.value > 0) {

              // Bestimmen, ob wir links oder rechts sind, um die Welle zu steuern
              bool isLikeSide = (_lastProcessedAction == SwipeAction.like) || (_lastProcessedAction == null && likeGlow > 0);

              double blendFactor = 0.0;
              if (isLikeSide) {
                  // Bei Like-Glow/Flash, rechte Bubbles stärker einfärben
                  blendFactor = (_swipeFeedbackController.value * (blob.position.dx + 0.5)).clamp(0.0, 1.0);
              } else {
                  // Bei Dislike-Glow/Flash, linke Bubbles stärker einfärben
                  blendFactor = (_swipeFeedbackController.value * (1.5 - blob.position.dx)).clamp(0.0, 1.0);
              }

              final easedBlendFactor = Curves.easeOutCubic.transform(blendFactor);
              finalColor = Color.lerp(spotifyBlendedColor, feedbackColor, easedBlendFactor)!;
          }
          blob.color = finalColor;
          // --- ENDE ---
        }
        
        final auroraOpacity = morphValue * (1 - homeTransition);

        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: LiquidBlobPainter(blobs: _blobs, morphValue: morphValue, homeTransition: homeTransition),
            ),
            Opacity(
              opacity: auroraOpacity.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF9B51E0).withOpacity(0.3 * morphValue),
                      Colors.black.withOpacity(0.8),
                      const Color(0xFF2D9CDB).withOpacity(0.3 * morphValue),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LiquidBlobPainter extends CustomPainter {
  final List<Blob> blobs;
  final double morphValue;
  final double homeTransition;

  LiquidBlobPainter({required this.blobs, required this.morphValue, required this.homeTransition});

  @override
  void paint(Canvas canvas, Size size) {
    // Blur wird auf dem Home-Screen stärker
    final double sigma = lerpDouble(15, 35, homeTransition)!;
    
    final filterPaint = Paint()
      ..imageFilter = ImageFilter.compose(
        outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
        inner: ColorFilter.matrix([1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 18, -8]),
      );
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), filterPaint);
    for (final blob in blobs) {
      final paint = Paint()..color = blob.color;
      // Radius wird auf dem Home-Screen kleiner
      final radius = lerpDouble(blob.radius, blob.radius * 0.5, homeTransition)!; 
      
      canvas.drawCircle(
        Offset(blob.position.dx * size.width, blob.position.dy * size.height), 
        radius * size.shortestSide * 0.6, 
        paint
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiquidBlobPainter oldDelegate) => true;
}
