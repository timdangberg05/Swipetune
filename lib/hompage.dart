import 'dart:math';
import 'package:flutter/material.dart';
import 'song.dart';

void main() {
  runApp(SwipeTuneApp());
}

class SwipeTuneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeTune',
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 5, 224, 82),
        useMaterial3: true,
      ),
      home: SwipeHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SwipeHomePage extends StatefulWidget {
  @override
  _SwipeHomePageState createState() => _SwipeHomePageState();
}

class _SwipeHomePageState extends State<SwipeHomePage> with TickerProviderStateMixin {
  final List<Song> _songs = [
    Song(
      title: "Levitating",
      artist: "Dua Lipa",
      coverUrl: "https://upload.wikimedia.org/wikipedia/en/f/f7/Dua_Lipa_-_Levitating.png",
    ),
    Song(
      title: "Blinding Lights",
      artist: "The Weeknd",
      coverUrl: "https://upload.wikimedia.org/wikipedia/en/e/e6/The_Weeknd_-_Blinding_Lights.png",
    ),
    Song(
      title: "Shape of You",
      artist: "Ed Sheeran",
      coverUrl: "https://upload.wikimedia.org/wikipedia/en/4/45/Shape_Of_You_%28Official_Single_Cover%29_by_Ed_Sheeran.png",
    ),
  ];

  int _currentIndex = 0;
  final List<Song> _liked = [];
  final List<Song> _disliked = [];

  // Drag state
  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0; // radians

  late AnimationController _animateController;
  late Animation<Offset> _animationOffset;
  late Animation<double> _animationRotation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animateController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _animateController.dispose();
    super.dispose();
  }

  Song? get _currentSong => _currentIndex < _songs.length ? _songs[_currentIndex] : null;

  void _startAutoAnimate(Offset targetOffset, double targetRotation, { required bool liked }) {
    if (_isAnimating) return;
    _isAnimating = true;

    _animationOffset = Tween<Offset>(
      begin: _cardOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _animateController, curve: Curves.easeOut));

    _animationRotation = Tween<double>(
      begin: _cardRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: _animateController, curve: Curves.easeOut));

    _animateController.reset();
    _animateController.addListener(() {
      setState(() {
        _cardOffset = _animationOffset.value;
        _cardRotation = _animationRotation.value;
      });
    });

    _animateController.forward().then((_) {
      // After animation completes, register like/dislike
      if (liked) {
        _liked.add(_songs[_currentIndex]);
      } else {
        _disliked.add(_songs[_currentIndex]);
      }
    });
  }

  void _onAnimationComplete() {
    // Move to next song and reset transforms
    _animateController.removeListener(() {}); // no-op: safe cleanup
    setState(() {
      _currentIndex++;
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
      _isAnimating = false;
    });
    _animateController.reset();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _cardOffset += details.delta;
      _cardRotation = (pi / 180) * (_cardOffset.dx / 20); // small rotation based on dx
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final dx = _cardOffset.dx;
    const threshold = 150; // pixels to trigger like/dislike

    if (dx > threshold) {
      // swipe right = like
      final screenWidth = MediaQuery.of(context).size.width;
      _startAutoAnimate(Offset(screenWidth * 1.2, _cardOffset.dy + details.velocity.pixelsPerSecond.dy / 10), 0.5, liked: true);
    } else if (dx < -threshold) {
      // swipe left = dislike
      final screenWidth = MediaQuery.of(context).size.width;
      _startAutoAnimate(Offset(-screenWidth * 1.2, _cardOffset.dy + details.velocity.pixelsPerSecond.dy / 10), -0.5, liked: false);
    } else {
      // return to center
      _startReturnToCenter();
    }
  }

  void _startReturnToCenter() {
    if (_isAnimating) return;
    _isAnimating = true;

    _animationOffset = Tween<Offset>(begin: _cardOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _animateController, curve: Curves.easeOut));
    _animationRotation = Tween<double>(begin: _cardRotation, end: 0.0)
        .animate(CurvedAnimation(parent: _animateController, curve: Curves.easeOut));

    _animateController.reset();
    _animateController.addListener(() {
      setState(() {
        _cardOffset = _animationOffset.value;
        _cardRotation = _animationRotation.value;
      });
    });

    _animateController.forward().then((_) {
      setState(() {
        _cardOffset = Offset.zero;
        _cardRotation = 0.0;
        _isAnimating = false;
      });
      _animateController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SwipeTune'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(child: Text('${_liked.length} ♥  ${_disliked.length} ✕')),
          )
        ],
      ),
      body: song == null
          ? _buildEmptyState()
          : GestureDetector(
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade700,
                          Colors.deepPurple.shade900,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // optionally render next card behind (if exists)
                  if (_currentIndex + 1 < _songs.length)
                    _buildBehindCard(_songs[_currentIndex + 1]),

                  // top card
                  _buildTopCard(song),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 72, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            "Keine Songs mehr",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // For demo: reset
              setState(() {
                _currentIndex = 0;
                _liked.clear();
                _disliked.clear();
              });
            },
            child: const Text("Erneut laden"),
          )
        ],
      ),
    );
  }

  Widget _buildBehindCard(Song song) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 36),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(song.coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _coverFallback()),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(song.artist, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(Song song) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width;
    final cardHeight = screenSize.height;

    return Center(
      child: Transform.translate(
        offset: _cardOffset,
        child: Transform.rotate(
          angle: _cardRotation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 18),
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // cover image
                    Image.network(
                      song.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverFallback(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade900,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),

                    // dark fade at bottom for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // top-left small badge showing swipe hint
                    Positioned(
                      left: 16,
                      top: 40,
                      child: Opacity(
                        opacity: 0.9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                          child: const Text("Swipe → Like  •  ← Dislike", style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    ),

                    // song info bottom-left
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 48,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(song.artist, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                        ],
                      ),
                    ),

                    // like / dislike icon overlays while dragging
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: _buildDragIndicator(),
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
  }

  Widget _coverFallback() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(child: Icon(Icons.music_note, size: 56, color: Colors.white70)),
    );
  }

  Widget _buildDragIndicator() {
    // show a semi-transparent icon while dragging to indicate like/dislike
    final dx = _cardOffset.dx;
    final opacity = (dx.abs() / 150).clamp(0.0, 1.0);
    if (dx > 0) {
      return Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(80, -100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 72, color: Colors.greenAccent.shade400),
              const SizedBox(height: 8),
              Text("Like", style: TextStyle(color: Colors.greenAccent.shade400, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else if (dx < 0) {
      return Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(-80, -100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: 72, color: Colors.redAccent.shade200),
              const SizedBox(height: 8),
              Text("Dislike", style: TextStyle(color: Colors.redAccent.shade200, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
