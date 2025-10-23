import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // Für lerpDouble
import 'package:provider/provider.dart';
import 'package:swipetune/screens/songdetails.dart';
import '../providers/spotify_data_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/stacked_card.dart';

class SwipeHomePage extends StatefulWidget {
  const SwipeHomePage({super.key});

  @override
  _SwipeHomePageState createState() => _SwipeHomePageState();
}

class _SwipeHomePageState extends State<SwipeHomePage> with TickerProviderStateMixin {

  bool _isPlaying = false;
  late AnimationController _cardAnimationController;
  double _screenWidth = 0;

  @override
  void initState() {
    super.initState();

    // Der NEUE zentrale Controller für die Swipe-Physik
    _cardAnimationController = AnimationController(
      vsync: this,
      lowerBound: -1.0, // -1.0 = Dislike
      upperBound: 1.0,  // 1.0 = Like
      value: 0.0,      // 0.0 = Center
      duration: const Duration(milliseconds: 300), // Dauer für Snap/Completion
    );

    _cardAnimationController.addListener(_onAnimationUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenWidth = MediaQuery.of(context).size.width;
      final provider = context.read<SpotifyDataProvider>();
      if(provider.tracks.isEmpty) {
        provider.loadDiscoveryTracks();
      }
    });
  }

  @override
  void dispose() {
    _cardAnimationController.removeListener(_onAnimationUpdate);
    _cardAnimationController.dispose();
    super.dispose();
  }

  // Diese Methode wird JEDEN Frame aufgerufen, während die Karte animiert wird
  void _onAnimationUpdate() {
    // Aktualisiere den Provider-Notifier für das Hintergrund-Feedback
    final provider = context.read<SpotifyDataProvider>();
    provider.swipeProgressNotifier.value = _cardAnimationController.value;

    // setState() ist hier nicht nötig, da wir einen AnimatedBuilder verwenden
  }

  /// Wird aufgerufen, NACHDEM die Fling/Animate-Animation beendet ist
  void _handleSwipeComplete(SwipeAction action) {
    final provider = context.read<SpotifyDataProvider>();

    if (action == SwipeAction.like) {
      provider.likeTrack();
    } else {
      provider.dislikeTrack();
    }

    // WICHTIG: Setze den Controller sofort für die nächste Karte zurück.
    // Da der provider.likeTrack() den currentIndex ändert, sieht der User
    // die neue Karte direkt in der Mittelposition.
    _cardAnimationController.value = 0.0;

    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpotifyDataProvider>(
      builder: (context, provider, child) {
        final track = provider.currentTrack;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                if (provider.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                if (!provider.isLoading && track != null)
                  // AnimatedBuilder ist effizienter als setState() im Listener
                  AnimatedBuilder(
                    animation: _cardAnimationController,
                    builder: (context, _) {
                      final progress = _cardAnimationController.value;
                      final cardOffset = Offset(progress * _screenWidth * 1.1, 0);
                      final cardRotation = progress * (math.pi / 20);

                      return Center(
                        child: Stack(
                          key: ValueKey(provider.currentIndex),
                          alignment: Alignment.center,
                          children: [
                            // --- Der KARTEN-STAPEL (Hintergrund) ---
                            // Zeigt die nächsten 3 Karten
                            for (int i = 3; i >= 1; i--)
                              if (provider.currentIndex + i < provider.tracks.length)
                                GlassStackedCard(
                                  track: provider.tracks[provider.currentIndex + i],
                                  position: i.toDouble(),
                                  swipeProgress: progress, // <-- Live-Fortschritt!
                                ),

                            // --- Die OBERSTE KARTE ---
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SongDetailPage(track: track),
                                  ),
                                );
                              },
                              onHorizontalDragStart: (details) {
                                // Stoppe jede laufende Snap-Animation
                                _cardAnimationController.stop();
                              },
                              onHorizontalDragUpdate: (details) {
                                // Der Finger "schiebt" den Controller-Wert
                                // Die 'Reibung' (screenWidth * 0.8) sorgt für ein gutes Gefühl
                                double friction = (_screenWidth == 0) ? 300.0 : _screenWidth * 0.8;
                                _cardAnimationController.value += details.delta.dx / friction;
                              },
                              onHorizontalDragEnd: (details) {
                                final velocity = details.velocity.pixelsPerSecond.dx;
                                final progress = _cardAnimationController.value;

                                // 1. "Fling"-Check (schneller Wisch)
                                if (velocity.abs() > 800.0) {
                                  final target = velocity > 0 ? 1.0 : -1.0;
                                  // Fling-Animation zur Seite
                                  _cardAnimationController.fling(velocity: velocity / _screenWidth).then((_) {
                                    _handleSwipeComplete(target > 0 ? SwipeAction.like : SwipeAction.dislike);
                                  });
                                }
                                // 2. "Position"-Check (langsamer Drag)
                                else if (progress.abs() > 0.4) {
                                  final target = progress > 0 ? 1.0 : -1.0;
                                  // Animation zur Seite
                                  _cardAnimationController.animateTo(target, curve: Curves.easeOut).then((_) {
                                    _handleSwipeComplete(target > 0 ? SwipeAction.like : SwipeAction.dislike);
                                  });
                                }
                                // 3. "Snap-Back"-Check (zurück zur Mitte)
                                else {
                                  _cardAnimationController.animateTo(0.0, curve: Curves.elasticOut);
                                }
                              },
                              child: Transform.translate(
                                offset: cardOffset,
                                child: Transform.rotate(
                                  angle: cardRotation,
                                  child: GlassSongCard(
                                    track: track,
                                    isPlaying: _isPlaying,
                                    onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}
