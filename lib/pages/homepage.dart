import 'package:flutter/material.dart';
import '/homepage_songs/song.dart';
import '/homepage_widgets/song_card.dart';
import '/homepage_widgets/stacked_card.dart';
import '/homepage_widgets/player_bar.dart';
import '/homepage_widgets/empty_state.dart';

class SwipeHomePage extends StatefulWidget {
  const SwipeHomePage({super.key});

  @override
  _SwipeHomePageState createState() => _SwipeHomePageState();
}

class _SwipeHomePageState extends State<SwipeHomePage> {
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
    Song(
      title: "Watermelon Sugar",
      artist: "Harry Styles",
      coverUrl:
          "https://upload.wikimedia.org/wikipedia/en/1/1a/Harry_Styles_-_Watermelon_Sugar.png",
    ),
    Song(
      title: "Dance Monkey",
      artist: "Tones and I",
      coverUrl:
          "https://upload.wikimedia.org/wikipedia/en/4/4a/Tones_and_I_-_Dance_Monkey.png",
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
      if (liked) _liked.add(_songs[_currentIndex]);
      else _disliked.add(_songs[_currentIndex]);

      if (_currentIndex < _songs.length - 1) _currentIndex++;
      else _currentIndex = 0;

      _swipeOffset = 0;
    });
  }

  void _reloadSongs() {
    setState(() {
      _currentIndex = 0;
      _liked.clear();
      _disliked.clear();
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

            // Gestapelte Song-Karten
            if (song != null)
              Center(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() => _swipeOffset += details.delta.dx);
                  },
                  onHorizontalDragEnd: (details) {
                    final width = MediaQuery.of(context).size.width;
                    if (_swipeOffset > width * 0.25) _nextSong(liked: true);
                    else if (_swipeOffset < -width * 0.25) _nextSong(liked: false);
                    else setState(() => _swipeOffset = 0);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 4; i >= 1; i--)
                        if (_currentIndex + i < _songs.length)
                          StackedCardUpwards(
                            song: _songs[_currentIndex + i],
                            position: i.toDouble(),
                          ),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Transform.translate(
                          key: ValueKey(song.title),
                          offset: Offset(_swipeOffset, 0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: SongCard(song: song),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              EmptyState(onReload: _reloadSongs),

            // PlayerBar immer am unteren Rand
            Align(
              alignment: Alignment.bottomCenter,
              child: song != null
              ?
                PlayerBar(
                  song: song,
                  isPlaying: _isPlaying,
                  onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
                )
                : Container(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}
