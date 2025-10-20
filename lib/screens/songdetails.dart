import 'package:flutter/material.dart';
import 'package:swipetune/models/Track.dart';
import '/widgets/liquid_background.dart';
import 'package:url_launcher/url_launcher.dart';

class SongDetailPage extends StatefulWidget {
  final Track track;
  const SongDetailPage({super.key, required this.track});

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController _timeController;
  late final AnimationController _colorController;
  late final AnimationController _morphController;
  late final ValueNotifier<Offset?> _logoCenterNotifier;

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

  Future<void> _launchPreviewUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// Animated liquid crystal background
          Positioned.fill(
            child: LiquidGlassBackground(
              time: _timeController,
              colorTransitionValue: _colorController,
              spotifyLogoCenterNotifier: _logoCenterNotifier,
              backgroundMorphController: _morphController,
            ),
          ),

          /// Subtle overlay for readability
          Container(color: Colors.black.withOpacity(0.25)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Central glowing container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.25),
                          width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// Album cover
                        Container(
                          width: screenWidth * 0.65,
                          height: screenWidth * 0.65,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 2,
                              )
                            ],
                            image: DecorationImage(
                              image: NetworkImage(track.albumImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// Song title
                        Text(
                          track.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        /// Artist name
                        Text(
                          track.artist,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// Album info below cover
                        _buildInfoRow(
                          Icons.album,
                          "Album",
                          track.albumName,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.calendar_today,
                          "Release Date",
                          track.releaseDate,
                        ),

                        const SizedBox(height: 25),

                        /// Popularity & preview info
                        _buildInfoRow(Icons.star, "Popularity",
                            "${track.popularity} / 100"),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.music_note,
                          "Preview",
                          track.previewUrl != null
                              ? "Tap play to preview"
                              : "No preview available",
                        ),

                        const SizedBox(height: 30),

                        /// Play preview button (if available)
                        if (track.previewUrl != null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.cyanAccent.withOpacity(0.2),
                              side: BorderSide(
                                  color: Colors.cyanAccent.withOpacity(0.5),
                                  width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                            ),
                            onPressed: () {
                              _launchPreviewUrl(track.previewUrl!);
                            },
                            icon: const Icon(Icons.play_arrow,
                                color: Colors.white),
                            label: const Text(
                              "Play Preview",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 17,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
