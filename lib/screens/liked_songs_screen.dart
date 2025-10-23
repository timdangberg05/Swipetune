import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:swipetune/models/Track.dart';
import 'package:swipetune/models/personal_album.dart';
import 'package:swipetune/providers/spotify_data_provider.dart';
import 'package:swipetune/services/library_service.dart';
import 'package:swipetune/widgets/library/library_back_button.dart';
import 'package:swipetune/widgets/liquid_background.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);
  late AnimationController _backgroundController;
  late AnimationController _timeController;
  late AnimationController _homeTransitionController;
  late Animation<double> _timeAnimation;
  late Animation<double> _backgroundMorphAnimation;
  late Animation<double> _homeTransitionAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffsetNotifier.value = _scrollOffsetNotifier.value = _scrollController.offset;
    });

    // Animation controller für den morphenden Hintergrund
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20), // Langsam für organische Bewegung
      vsync: this,
    )..repeat();

    _timeController = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    )..repeat(reverse: true);

    // Home-Transition Controller für Blob-Verhalten (von Nav-Bar zurück zu freiem Wandern)
    _homeTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800), // Schnell für Übergang
      vsync: this,
    );

    _timeAnimation = Tween<double>(begin: 0, end: 1).animate(_timeController);
    _backgroundMorphAnimation = Tween<double>(begin: 0, end: 0.8).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
    _homeTransitionAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _homeTransitionController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Starte die Transition-Animation, um Blobs von Nav-Bar frei zu lösen
    _homeTransitionController.forward();

    // TODO: Load liked tracks
    // context.read<SpotifyDataProvider>().loadLikedTracks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    _backgroundController.dispose();
    _timeController.dispose();
    _homeTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top + 80;
    final horizontalPadding = size.width * 0.05;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;

    return Stack(
      children: [
        LiquidGlassBackground(
          time: _timeAnimation,
          colorTransitionValue: _backgroundMorphAnimation,
          spotifyLogoCenterNotifier: ValueNotifier<Offset?>(null),
          swipeActionNotifier: ValueNotifier<SwipeAction?>(null),
          backgroundMorphController: _backgroundController,
          homeTransitionController: _homeTransitionAnimation,
        ),
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: topPadding,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: size.width * 0.02, bottom: size.height * 0.015),
                  child: Text(
                    'Liked Songs',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: bottomPadding,
              ),
              sliver: Selector<SpotifyDataProvider, List<Track>>(
                selector: (_, provider) => provider.likedTracks,
                builder: (context, tracks, _) {
                  if (tracks.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
                        return RepaintBoundary(
                          child: SongItemWithMenu(
                            track: track,
                            index: index,
                            scrollController: _scrollController,
                          ),
                        );
                      },
                      childCount: tracks.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: horizontalPadding,
          right: horizontalPadding,
          child: Row(
            children: [
              LibraryBackButton(onTap: () {
                Navigator.of(context).pop();
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// Modified SongItem to include menu for adding to albums
class SongItemWithMenu extends StatelessWidget {
  final Track track;
  final int index;
  final ScrollController scrollController;

  const SongItemWithMenu({
    super.key,
    required this.track,
    required this.index,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Play the song, perhaps
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '${index + 1}',
              style: GoogleFonts.manrope(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                _showOptions(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final libraryService = LibraryService();
        final box = libraryService.getAlbumsListenable();

        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.white.withOpacity(0.1),
              height: MediaQuery.of(context).size.height * 0.5,
              child: ValueListenableBuilder(
                valueListenable: box,
                builder: (context, Box<PersonalAlbum> box, _) {
                  final albums = box.values.toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: albums.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return ListTile(
                        title: Text(
                          album.name,
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          libraryService.addTrackToAlbum(
                            album.key.toString(),
                            track.id,
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${album.name}'),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
