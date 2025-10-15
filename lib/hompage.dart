import 'package:flutter/material.dart';
import 'song.dart';

void main() {
  runApp(SwipeTuneApp());
}

class SwipeTuneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SwipeHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SwipeHomePage extends StatefulWidget {
  @override
  _SwipeHomePageState createState() => _SwipeHomePageState();
}

class _SwipeHomePageState extends State<SwipeHomePage>
    with SingleTickerProviderStateMixin {
  final List<Song> _songs = [
    Song(
      title: "Levitating",
      artist: "Dua Lipa",
      coverUrl:
          "https://upload.wikimedia.org/wikipedia/en/f/f7/Dua_Lipa_-_Levitating.png",
    ),
    Song(
      title: "Blinding Lights",
      artist: "The Weeknd",
      coverUrl:
          "https://upload.wikimedia.org/wikipedia/en/e/e6/The_Weeknd_-_Blinding_Lights.png",
    ),
    Song(
      title: "Shape of You",
      artist: "Ed Sheeran",
      coverUrl:
          "https://upload.wikimedia.org/wikipedia/en/b/b4/Shape_Of_You_%28Official_Single_Cover%29_by_Ed_Sheeran.png",
    ),
  ];

  int _currentIndex = 0;
  final List<Song> _liked = [];
  final List<Song> _disliked = [];
  bool _isPlaying = false;

  double _swipeOffset = 0.0;

  Song? get _currentSong =>
      _currentIndex < _songs.length ? _songs[_currentIndex] : null;

  void _nextSong({bool liked = true}) {
    if (_currentSong == null) return;
    setState(() {
      if (liked) {
        _liked.add(_songs[_currentIndex]);
      } else {
        _disliked.add(_songs[_currentIndex]);
      }
      if (_currentIndex < _songs.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _swipeOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Counter oben rechts
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_liked.length} ♥  ${_disliked.length} ✕',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Kartenbereich mit Swipe
            if (song != null)
              Center(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _swipeOffset += details.delta.dx;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    final width = MediaQuery.of(context).size.width;
                    if (_swipeOffset > width * 0.25) {
                      _nextSong(liked: true);
                    } else if (_swipeOffset < -width * 0.25) {
                      _nextSong(liked: false);
                    } else {
                      setState(() => _swipeOffset = 0);
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Transform.translate(
                      key: ValueKey(song.title),
                      offset: Offset(_swipeOffset, 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: _buildCard(song),
                          ),

                          // Like / Dislike Icons beim Swipe
                          if (_swipeOffset != 0)
                            Opacity(
                              opacity:
                                  (_swipeOffset.abs() / 150).clamp(0.0, 1.0),
                              child: Icon(
                                _swipeOffset > 0
                                    ? Icons.favorite
                                    : Icons.close,
                                color: _swipeOffset > 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                size: 80,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              _buildEmptyState(),

            // Player-Bar unten
            if (song != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildPlayerBar(song),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Song song) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        color: Colors.grey.shade900,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              song.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverFallback(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.black,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _coverFallback() => Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(Icons.music_note, size: 56, color: Colors.white70),
        ),
      );

  Widget _buildPlayerBar(Song song) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _isPlaying ? 0.3 : 0.0,
                backgroundColor: Colors.grey.shade800,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                minHeight: 3,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        song.coverUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.music_note,
                              color: Colors.white70, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: () {},
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () =>
                            setState(() => _isPlaying = !_isPlaying),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, size: 72, color: Colors.white70),
            const SizedBox(height: 16),
            const Text("Keine Songs mehr",
                style: TextStyle(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
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
