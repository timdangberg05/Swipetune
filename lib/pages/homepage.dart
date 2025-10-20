import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:swipetune/screens/songdetails.dart';
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

  Color _leftGlowColor = Colors.transparent;
  Color _rightGlowColor = Colors.transparent;
  double _leftGlowWidth = 0;
  double _rightGlowWidth = 0;

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

  void _triggerGlow({required bool isLike}) {
    final width = MediaQuery.of(context).size.width;
    setState(() {
      if (isLike) {
        _rightGlowColor = Colors.greenAccent.withOpacity(0.8);
        _rightGlowWidth = width;
      } else {
        _leftGlowColor = Colors.redAccent.withOpacity(0.8);
        _leftGlowWidth = width;
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _leftGlowColor = Colors.transparent;
        _rightGlowColor = Colors.transparent;
        _leftGlowWidth = 0;
        _rightGlowWidth = 0;
      });
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
                // Linker Glow (Dislike - von links bis zur Mitte)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _leftGlowWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _leftGlowColor,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Rechter Glow (Like - von rechts bis zur Mitte)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: _rightGlowWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          _rightGlowColor,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

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
                          onHorizontalDragUpdate: (details) =>
                              setState(() => _dragOffset += details.delta),
                          onHorizontalDragEnd: (details) {
                            final width = MediaQuery.of(context).size.width;
                            final halfScreen = width * 0.5;
                            if (_dragOffset.dx.abs() > MediaQuery.of(context).size.width * 0.4) {
                              if (_dragOffset.dx > 0) {
                                provider.likeTrack();
                                _triggerGlow(isLike: true);
                              } else {
                                provider.dislikeTrack();
                                _triggerGlow(isLike: false);
                              }

                              setState(() {
                                _dragOffset = Offset.zero;
                                _isPlaying = false;
                              });
                            } else {

                              _snapAnimation = Tween<Offset>(
                                begin: _dragOffset,
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _snapAnimationController,
                                  curve: Curves.elasticOut,
                                ),
                              );
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