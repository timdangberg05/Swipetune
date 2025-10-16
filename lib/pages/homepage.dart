import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../homepage_songs/song.dart';
import '../homepage_widgets/empty_state.dart';
import '../widgets/song_card.dart';
import '../widgets/stacked_card.dart';

class SwipeHomePage extends StatefulWidget {
  const SwipeHomePage({super.key});

  @override
  _SwipeHomePageState createState() => _SwipeHomePageState();
}

class _SwipeHomePageState extends State<SwipeHomePage> with TickerProviderStateMixin {
  final List<Song> _songs = [
    Song(title: "Levitating", artist: "Dua Lipa", coverUrl: "https://upload.wikimedia.org/wikipedia/en/f/f7/Dua_Lipa_-_Levitating.png"),
    Song(title: "Blinding Lights", artist: "The Weeknd", coverUrl: "https://upload.wikimedia.org/wikipedia/en/e/e6/The_Weeknd_-_Blinding_Lights.png"),
    Song(title: "Shape of You", artist: "Ed Sheeran", coverUrl: "https://upload.wikimedia.org/wikipedia/en/b/b4/Shape_Of_You_%28Official_Single_Cover%29_by_Ed_Sheeran.png"),
    Song(title: "Watermelon Sugar", artist: "Harry Styles", coverUrl: "https://upload.wikimedia.org/wikipedia/en/1/1a/Harry_Styles_-_Watermelon_Sugar.png"),
    Song(title: "Dance Monkey", artist: "Tones and I", coverUrl: "https://upload.wikimedia.org/wikipedia/en/4/4a/Tones_and_I_-_Dance_Monkey.png"),
  ];

  int _currentIndex = 0;
  bool _isPlaying = false; // Zustand für den Player
  final List<Song> _liked = [];
  final List<Song> _disliked = [];
  Offset _dragOffset = Offset.zero;

  late AnimationController _snapAnimationController;
  late Animation<Offset> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _snapAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_snapAnimationController);
    _snapAnimationController.addListener(() => setState(() => _dragOffset = _snapAnimation.value));
  }

  @override
  void dispose() {
    _snapAnimationController.dispose();
    super.dispose();
  }

  Song? get _currentSong => _currentIndex < _songs.length ? _songs[_currentIndex] : null;

  void _nextSong({required bool liked}) {
    if (_currentSong == null) return;
    setState(() {
      if (liked) _liked.add(_songs[_currentIndex]);
      else _disliked.add(_songs[_currentIndex]);
      _currentIndex++;
      _dragOffset = Offset.zero;
      _isPlaying = false; // Player beim nächsten Song zurücksetzen
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
          
            if (song != null)
              Center(
                child: Stack(
                  key: ValueKey(_currentIndex),
                  alignment: Alignment.center,
                  children: [
                    if (_currentIndex + 1 < _songs.length)
                      GlassStackedCard(song: _songs[_currentIndex + 1], position: 1),

                    GestureDetector(
                      onHorizontalDragUpdate: (details) => setState(() => _dragOffset += details.delta),
                      onHorizontalDragEnd: (details) {
                        if (_dragOffset.dx.abs() > MediaQuery.of(context).size.width * 0.4) {
                          _nextSong(liked: _dragOffset.dx > 0);
                        } else {
                          _snapAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
                              .animate(CurvedAnimation(parent: _snapAnimationController, curve: Curves.elasticOut));
                          _snapAnimationController.forward(from: 0.0);
                        }
                      },
                      child: Transform.translate(
                        offset: _dragOffset,
                        child: Transform.rotate(
                          angle: (_dragOffset.dx / MediaQuery.of(context).size.width) * (math.pi / 20),
                          child: GlassSongCard(
                            song: song,
                            isPlaying: _isPlaying,
                            onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(child: Text("Keine Songs mehr.", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

