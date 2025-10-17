import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
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
  Offset _dragOffset = Offset.zero;

  late AnimationController _snapAnimationController;
  late Animation<Offset> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _snapAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_snapAnimationController);
    _snapAnimationController.addListener(() => setState(() => _dragOffset = _snapAnimation.value));
    
    // Lade Tracks vom Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotifyDataProvider>().loadTracks();
    });
  }

  @override
  void dispose() {
    _snapAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpotifyDataProvider>(
      builder: (context, provider, child) {
        final track = provider.currenTrack;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                // Loading Indicator
                if (provider.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                
                // Song Cards
                if (!provider.isLoading && track != null)
                  Center(
                    child: Stack(
                      key: ValueKey(provider.currentIndex),
                      alignment: Alignment.center,
                      children: [
                        // Nächste Karte im Stapel
                        if (provider.currentIndex + 1 < provider.tracks.length)
                          GlassStackedCard(
                            track: provider.tracks[provider.currentIndex + 1], 
                            position: 1,
                          ),

                        // Aktuelle Karte mit Swipe
                        GestureDetector(
                          onHorizontalDragUpdate: (details) => 
                            setState(() => _dragOffset += details.delta),
                          onHorizontalDragEnd: (details) {
                            if (_dragOffset.dx.abs() > MediaQuery.of(context).size.width * 0.4) {
                              // Swipe erfolgreich
                              if (_dragOffset.dx > 0) {
                                provider.likeTrack();
                              } else {
                                provider.dislikeTrack();
                              }
                              setState(() {
                                _dragOffset = Offset.zero;
                                _isPlaying = false;
                              });
                            } else {
                              // Snap zurück
                              _snapAnimation = Tween<Offset>(
                                begin: _dragOffset, 
                                end: Offset.zero
                              ).animate(CurvedAnimation(
                                parent: _snapAnimationController, 
                                curve: Curves.elasticOut
                              ));
                              _snapAnimationController.forward(from: 0.0);
                            }
                          },
                          child: Transform.translate(
                            offset: _dragOffset,
                            child: Transform.rotate(
                              angle: (_dragOffset.dx / MediaQuery.of(context).size.width) * (math.pi / 20),
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
                  )
                else if (!provider.isLoading && provider.tracks.isEmpty)
                  const Center(
                    child: Text(
                      "Keine Songs mehr.", 
                      style: TextStyle(color: Colors.white)
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
