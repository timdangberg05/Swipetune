import 'package:flutter/material.dart';
import 'package:swipetune/widgets/empty_state.dart';
import 'package:swipetune/widgets/player_bar.dart';
import 'package:swipetune/widgets/song_card.dart';
import 'package:swipetune/widgets/stacked_card.dart';
import '/homepage_songs/song.dart';
import '../API/SongService.dart';
import '../API/SpotifyApiClient.dart';
import '/widgets/liquid_background.dart'; // 🧩 dein LiquidGlassBackground importieren
import 'songdetails.dart';

class SwipeHomePage extends StatefulWidget {
  const SwipeHomePage({super.key});

  @override
  _SwipeHomePageState createState() => _SwipeHomePageState();
}

class _SwipeHomePageState extends State<SwipeHomePage>
    with TickerProviderStateMixin {
  List<Song> _songs = [];
  bool _isLoading = true;

  int _currentIndex = 0;
  final List<Song> _liked = [];
  final List<Song> _disliked = [];
  bool _isPlaying = false;
  double _swipeOffset = 0.0;

  // 🔥 Animationen für Liquid Background
  late final AnimationController _timeController;
  late final AnimationController _colorController;
  late final AnimationController _morphController;
  late final ValueNotifier<Offset?> _logoCenterNotifier;
  late final SongService _songService;

  @override
  void initState() {
    super.initState();

    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _logoCenterNotifier = ValueNotifier(null);
    _songService = SongService(SpotifyApiClient());
    _loadRealSongs();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _colorController.dispose();
    _morphController.dispose();
    _logoCenterNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadRealSongs() async {
  try {
    final tracks = await _songService.getTopTracks();
    print('✅ Tracks geladen: ${tracks.length}');

    setState(() {
      _songs = tracks.map((track) => Song
      (
        title: track.name,
        artist: track.artist,
        coverUrl: track.albumImageUrl ?? '',
      )).toList();
      _isLoading = false;
    });
    for (var track in tracks)
    {
      print( '  ${track.name} - ${track.artist}');
    }
  } catch (e) {
    print(' Fehler: $e');
    setState(() => _isLoading = false);
  }
}

  Song? get _currentSong =>
      _currentIndex < _songs.length ? _songs[_currentIndex] : null;

  void _nextSong({bool liked = true}) {
    if (_currentSong == null) return;
    setState(() {
      if (liked)
        _liked.add(_songs[_currentIndex]);
      else
        _disliked.add(_songs[_currentIndex]);

      if (_currentIndex < _songs.length - 1)
        _currentIndex++;
      else
        _currentIndex = 0;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 🌊 Flüssiger Hintergrund
            Positioned.fill(
              child: LiquidGlassBackground(
                time: _timeController,
                colorTransitionValue: _colorController,
                spotifyLogoCenterNotifier: _logoCenterNotifier,
                backgroundMorphController: _morphController,
              ),
            ),

            // 🌑 Dunkles Overlay für bessere Lesbarkeit
            Container(color: Colors.black.withOpacity(0.25)),

          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Lade deine Top Tracks...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            // ❤️ Like / Dislike Counter
            if(!_isLoading)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_liked.length} ♥  ${_disliked.length} ✕',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 🎵 Song-Karten + Swipe-Animation
            if (!_isLoading && song != null)
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 700),
                        pageBuilder: (_, __, ___) => SongDetailPage(song: song),
                        transitionsBuilder: (_, animation, __, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  onTapDown: (details) =>
                      _logoCenterNotifier.value = details.globalPosition,
                  onTapUp: (_) => _logoCenterNotifier.value = null,
                  onHorizontalDragUpdate: (details) {
                    setState(() => _swipeOffset += details.delta.dx);
                  },
                  onHorizontalDragEnd: (_) {
                    if (_swipeOffset > screenWidth * 0.25)
                      _nextSong(liked: true);
                    else if (_swipeOffset < -screenWidth * 0.25)
                      _nextSong(liked: false);
                    else
                      setState(() => _swipeOffset = 0);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hintergrundkarten (gestapelt)
                      for (int i = 4; i >= 1; i--)
                        if (_currentIndex + i < _songs.length)
                          StackedCardUpwards(
                            song: _songs[_currentIndex + i],
                            position: i.toDouble(),
                          ),

                      // Aktuelle Karte mit Swipe-Animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Transform.translate(
                          key: ValueKey(song.title),
                          offset: Offset(_swipeOffset, 0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: screenWidth * 0.85,
                                height: screenHeight * 0.55,
                                child: SongCard(song: song),
                              ),

                              // 💖 Flüssiges Icon (kleiner, rund, ohne Rotation)
                              if (_swipeOffset.abs() > 10)
                                Positioned(
                                  top: 40,
                                  left: _swipeOffset > 0 ? 20 : null,
                                  right: _swipeOffset < 0 ? 20 : null,
                                  child: AnimatedBuilder(
                                    animation: _colorController,
                                    builder: (context, _) {
                                      // 🌈 Farbverlauf
                                      final colorTween =
                                          TweenSequence<Color?>([
                                        TweenSequenceItem(
                                          tween: ColorTween(
                                              begin: Colors.purpleAccent,
                                              end: Colors.tealAccent),
                                          weight: 1,
                                        ),
                                        TweenSequenceItem(
                                          tween: ColorTween(
                                              begin: Colors.tealAccent,
                                              end: Colors.blueAccent),
                                          weight: 1,
                                        ),
                                        TweenSequenceItem(
                                          tween: ColorTween(
                                              begin: Colors.blueAccent,
                                              end: Colors.pinkAccent),
                                          weight: 1,
                                        ),
                                      ]);
                                      final dynamicColor =
                                          colorTween.evaluate(_colorController)!;

                                      // ✨ Dezente Skalierung
                                      final scale = (_swipeOffset.abs() / 150)
                                          .clamp(0.9, 1.05);

                                      return Opacity(
                                        opacity:
                                            (_swipeOffset.abs() / 150).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                dynamicColor.withOpacity(0.4),
                                                Colors.transparent
                                              ],
                                              stops: const [0.0, 1.0],
                                            ),
                                          ),
                                          child: Icon(
                                            _swipeOffset > 0
                                                ? Icons.favorite
                                                : Icons.close,
                                            color: dynamicColor,
                                            size: 60 * scale, // 🎯 kleiner & ruhiger
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!_isLoading && _songs.isEmpty)
              EmptyState(onReload: _reloadSongs),

            // 🎧 Player unten
            if(!_isLoading)
            Align(
              alignment: Alignment.bottomCenter,
              child: song != null
                  ? PlayerBar(
                      song: song,
                      isPlaying: _isPlaying,
                      onPlayPause: () =>
                          setState(() => _isPlaying = !_isPlaying),
                    )
                  : const SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}
