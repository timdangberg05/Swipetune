import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  Offset _dragOffset = Offset.zero;

  late AnimationController _snapAnimationController;
  late Animation<Offset> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _snapAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_snapAnimationController);
    _snapAnimationController.addListener(() => setState(() => _dragOffset = _snapAnimation.value));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SpotifyDataProvider>();
      if(provider.tracks.isEmpty)
      {
        provider.loadDiscoveryTracks();
      }
    });;
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
                  Center(
                    child: Stack(
                      key: ValueKey(provider.currentIndex),
                      alignment: Alignment.center,
                      children: [
                        for (int i = 1; i <= 5; i++)
                          if (provider.currentIndex + i < provider.tracks.length)
                            GlassStackedCard(
                              track: provider.tracks[provider.currentIndex + i],
                              position: i.toDouble(),
                            ),
                        // Nächste Karte im Stapel
                        if (provider.currentIndex + 1 < provider.tracks.length)
                          GlassStackedCard(
                            track: provider.tracks[provider.currentIndex + 1],
                            position: 1,
                          ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongDetailPage(track: track),
                              ),
                            );
                          },
                          onHorizontalDragUpdate: (details) {
                            setState(() => _dragOffset += details.delta);
                            provider.dragOffsetNotifier.value = _dragOffset;
                          },
                          onHorizontalDragEnd: (details) {
                            final width = MediaQuery.of(context).size.width;
                            final halfScreen = width * 0.5;
                            if (_dragOffset.dx.abs() > MediaQuery.of(context).size.width * 0.4) {
                              if (_dragOffset.dx > 0) {
                                provider.likeTrack();
                              } else {
                                provider.dislikeTrack();
                              }

                              setState(() {
                                _dragOffset = Offset.zero;
                                _isPlaying = false;
                              });
                              provider.dragOffsetNotifier.value = Offset.zero;
                            } else {
                              // Animate back to center
                              _snapAnimation = Tween<Offset>(
                                begin: _dragOffset,
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _snapAnimationController,
                                  curve: Curves.elasticOut,
                                ),
                              )..addListener(() {
                                provider.dragOffsetNotifier.value = _snapAnimation.value;
                              });
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
              ],
            ),
          ),
        );
      },
    );
  }
}
