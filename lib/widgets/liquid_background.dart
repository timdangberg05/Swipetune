import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:swipetune/models/blob.dart';

class LiquidGlassBackground extends StatefulWidget {
  final Animation<double> time;
  final Animation<double> colorTransitionValue;
  final ValueNotifier<Offset?> spotifyLogoCenterNotifier;
  final AnimationController? backgroundMorphController;
  final Animation<double>? homeTransitionController;

  const LiquidGlassBackground({
    super.key,
    required this.time,
    required this.colorTransitionValue,
    required this.spotifyLogoCenterNotifier,
    this.backgroundMorphController,
    this.homeTransitionController,
  });

  @override
  State<LiquidGlassBackground> createState() => _LiquidGlassBackgroundState();
}

class _LiquidGlassBackgroundState extends State<LiquidGlassBackground> {
  late final List<Blob> _blobs;
  final List<Color> _originalColors = [];
  final List<Color> _spotifyColors = [
    const Color(0xFF1DB954).withOpacity(0.6), const Color(0xFF1ED760).withOpacity(0.5),
    const Color(0xFF4AE280).withOpacity(0.5), const Color(0xFF2DEB70).withOpacity(0.4),
  ];

  @override
  void initState() {
    super.initState();
    _blobs = List.generate(4, (index) {
      final rand = math.Random();
      final color = Color.lerp(const Color(0xFF9B51E0).withOpacity(0.5), const Color(0xFF2D9CDB).withOpacity(0.5), rand.nextDouble())!;
      _originalColors.add(color);
      return Blob(
        position: Offset(rand.nextDouble(), rand.nextDouble()),
        radius: rand.nextDouble() * 0.15 + 0.2,
        velocity: Offset(rand.nextDouble() * 0.1 - 0.05, rand.nextDouble() * 0.1 - 0.05),
        color: color,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.time, widget.colorTransitionValue, widget.spotifyLogoCenterNotifier, widget.backgroundMorphController, widget.homeTransitionController]),
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final logoCenter = widget.spotifyLogoCenterNotifier.value;
        const repulsionRadius = 90.0;
        final morphValue = widget.backgroundMorphController?.value ?? 0.0;
        final homeTransition = widget.homeTransitionController?.value ?? 0.0;

        for (int i = 0; i < _blobs.length; i++) {
          final blob = _blobs[i];
          
          if (homeTransition > 0.0) {
            final navBarY = size.height - 55 - (MediaQuery.of(context).padding.bottom);
            final targetPosition = Offset(
              (size.width / (_blobs.length + 1)) * (i + 1),
              navBarY + (math.sin(i + widget.time.value * 2 * (i + 1)) * 15),
            );
            final currentPixelPosition = Offset(blob.position.dx * size.width, blob.position.dy * size.height);
            final newPosition = Offset.lerp(currentPixelPosition, targetPosition, 0.05)!;
            blob.position = Offset(newPosition.dx / size.width, newPosition.dy / size.height);
            blob.velocity *= (1 - homeTransition * 0.2);
          } else {
            blob.position += blob.velocity * 0.015;
            if (logoCenter != null) {
              final blobPixelPosition = Offset(blob.position.dx * size.width, blob.position.dy * size.height);
              final distanceVector = blobPixelPosition - logoCenter;
              if (distanceVector.distance < repulsionRadius && distanceVector.distance > 0.1) {
                final normal = (distanceVector / distanceVector.distance);
                final dot = blob.velocity.dx * normal.dx + blob.velocity.dy * normal.dy;
                blob.velocity = blob.velocity - (normal * (2 * dot));
                blob.position += Offset(normal.dx * 0.03, normal.dy * 0.03);
              }
            }
            if (blob.position.dx > 1.2) blob.position = Offset(-0.2, blob.position.dy);
            if (blob.position.dx < -0.2) blob.position = Offset(1.2, blob.position.dy);
            if (blob.position.dy > 1.2) blob.position = Offset(blob.position.dx, -0.2);
            if (blob.position.dy < -0.2) blob.position = Offset(blob.position.dx, 1.2);
          }
          blob.color = Color.lerp(_originalColors[i], _spotifyColors[i % _spotifyColors.length], widget.colorTransitionValue.value)!;
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
    // Der Unschärfe-Effekt wird stärker, je mehr die Blobs in die Leiste morphen.
    final double sigma = lerpDouble(25, 50, homeTransition)!;
    
    final filterPaint = Paint()
      ..imageFilter = ImageFilter.compose(
        outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
        inner: ColorFilter.matrix([1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 20, -10]),
      );
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), filterPaint);
    for (final blob in blobs) {
      // KORREKTUR: Die Farbe der Blobs verblasst nicht mehr. Sie bleiben sichtbar.
      final paint = Paint()..color = blob.color;
      // Der Radius der Blobs schrumpft, während sie sich der Leiste nähern.
      final radius = lerpDouble(blob.radius, blob.radius * 0.5, homeTransition)!;
      canvas.drawCircle(Offset(blob.position.dx * size.width, blob.position.dy * size.height), radius * size.shortestSide, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiquidBlobPainter oldDelegate) => true;
}

