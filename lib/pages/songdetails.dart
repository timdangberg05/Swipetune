import 'package:flutter/material.dart';
import '/homepage_songs/song.dart';
import '/widgets/liquid_background.dart';

class SongDetailPage extends StatefulWidget {
  final Song song;
  const SongDetailPage({super.key, required this.song});

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController _timeController;
  late final AnimationController _colorController;
  late final AnimationController _morphController;
  late final ValueNotifier<Offset?> _logoCenterNotifier;

  bool _isPlaying = false;

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
  }

  @override
  void dispose() {
    _timeController.dispose();
    _colorController.dispose();
    _morphController.dispose();
    _logoCenterNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          Positioned.fill(
            child: LiquidGlassBackground(
              time: _timeController,
              colorTransitionValue: _colorController,
              spotifyLogoCenterNotifier: _logoCenterNotifier,
              backgroundMorphController: _morphController,
            ),
          ),

          Container(color: Colors.black.withOpacity(0.25)),

          SafeArea(
            child: Column(
              children: [
                
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: screenWidth * 0.7,
                  height: screenWidth * 0.7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 25,
                        spreadRadius: 2,
                      )
                    ],
                    image: DecorationImage(
                      image: NetworkImage(song.coverUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  song.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
