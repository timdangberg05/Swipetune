import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/library/library_back_button.dart';
import '../widgets/library/playlist_item.dart';
import '../widgets/library/song_item.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  _PlaylistData? _selectedPlaylist;
  late AnimationController _morphController;
  final ScrollController _detailScrollController = ScrollController();
  double _scrollOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _detailScrollController.addListener(_onDetailScroll);
  }
  
  void _onDetailScroll() {
    setState(() {
      _scrollOffset = _detailScrollController.offset;
    });
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }
  
  void _openPlaylist(_PlaylistData playlist) {
    setState(() {
      _selectedPlaylist = playlist;
      _scrollOffset = 0.0;
    });
    _morphController.forward();
  }
  
  void _closePlaylist() {
    _morphController.reverse().then((_) {
      setState(() => _selectedPlaylist = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Library View
        IgnorePointer(
          ignoring: _selectedPlaylist != null,
          child: AnimatedOpacity(
            opacity: _selectedPlaylist == null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _buildMainLibraryView(context),
          ),
        ),
        
        // Playlist Detail View (morphs in)
        if (_selectedPlaylist != null)
          _buildPlaylistDetailView(context, _selectedPlaylist!),
      ],
    );
  }

  Widget _buildMainLibraryView(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90; // Nav bar space
    
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            left: size.width * 0.05,
            right: size.width * 0.05,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactStatsRow(context),
                SizedBox(height: size.height * 0.03),
                Padding(
                  padding: EdgeInsets.only(left: size.width * 0.02, bottom: size.height * 0.015),
                  child: Text(
                    'Your Library',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: size.width * 0.05,
            right: size.width * 0.05,
            bottom: bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final playlists = _getPlaylists();
                final playlist = playlists[index];
                return PlaylistItem(
                  name: playlist.name,
                  songCount: playlist.songCount,
                  icon: playlist.icon,
                  onTap: () => _openPlaylist(playlist),
                );
              },
              childCount: _getPlaylists().length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatsRow(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.02,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactStat(Icons.favorite, '247'),
              _buildCompactStat(Icons.library_music, '8'),
              _buildCompactStat(Icons.access_time, '12h'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistDetailView(BuildContext context, _PlaylistData playlist) {
    final size = MediaQuery.of(context).size;
    final morphAnim = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    return AnimatedBuilder(
      animation: morphAnim,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24 * (1 - morphAnim.value)),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 30 * morphAnim.value,
                sigmaY: 30 * morphAnim.value,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3 * morphAnim.value),
                child: _buildDetailContent(context, playlist, morphAnim.value),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailContent(BuildContext context, _PlaylistData playlist, double progress) {
    final size = MediaQuery.of(context).size;
    final songs = _getSongsForPlaylist(playlist.name);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    
    // Calculate collapse progress (0.0 = expanded, 1.0 = collapsed)
    final collapseProgress = (_scrollOffset / 150).clamp(0.0, 1.0);
    final expandedHeight = size.height * 0.35;
    final collapsedHeight = MediaQuery.of(context).padding.top + 60.0;
    
    return CustomScrollView(
      controller: _detailScrollController,
      slivers: [
        // Collapsing Header with morphing animation
        SliverPersistentHeader(
          pinned: true,
          delegate: _PlaylistHeaderDelegate(
            minHeight: collapsedHeight,
            maxHeight: expandedHeight,
            playlist: playlist,
            onBack: _closePlaylist,
            collapseProgress: collapseProgress,
          ),
        ),
        // Song List
        SliverPadding(
          padding: EdgeInsets.only(
            left: size.width * 0.05,
            right: size.width * 0.05,
            bottom: bottomPadding,
          ),
          sliver: SliverOpacity(
            opacity: progress,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SongItem(
                    title: songs[index].title,
                    artist: songs[index].artist,
                    duration: songs[index].duration,
                    index: index,
                    onTap: () {},
                  );
                },
                childCount: songs.length,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_PlaylistData> _getPlaylists() {
    return [
      _PlaylistData('Liked Songs', '247 songs', Icons.favorite),
      _PlaylistData('Recently Played', '32 songs', Icons.history),
      _PlaylistData('Chill Vibes', '45 songs', Icons.nights_stay),
      _PlaylistData('Workout', '28 songs', Icons.fitness_center),
      _PlaylistData('Focus', '67 songs', Icons.lightbulb_outline),
      _PlaylistData('Party Mix', '54 songs', Icons.celebration),
      _PlaylistData('Road Trip', '39 songs', Icons.directions_car),
      _PlaylistData('Sleep', '21 songs', Icons.bedtime),
    ];
  }

  List<_SongData> _getSongsForPlaylist(String playlistName) {
    return List.generate(
      15,
      (index) => _SongData(
        title: 'Song Title ${index + 1}',
        artist: 'Artist Name',
        duration: '3:${(index % 6 + 10).toString().padLeft(2, '0')}',
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for collapsing header with morph effect
class _PlaylistHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final _PlaylistData playlist;
  final VoidCallback onBack;
  final double collapseProgress;

  _PlaylistHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.playlist,
    required this.onBack,
    required this.collapseProgress,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);
    
    // Collapsed state: all in one line at back button height
    final collapsedTop = safeTop + 16.0; // Same as back button
    final backButtonWidth = size.width * 0.05 + 44.0; // Back button position + width
    
    // Icon size: 120px expanded → 28px collapsed
    final iconSize = 120 - (92 * progress);
    
    // Icon position: center when expanded → next to back button when collapsed
    final expandedIconLeft = (size.width - 120) / 2;
    final collapsedIconLeft = backButtonWidth + 8.0; // Right of back button with gap
    final iconLeft = expandedIconLeft + ((collapsedIconLeft - expandedIconLeft) * progress);
    
    final expandedIconTop = (maxHeight - minHeight) / 2;
    final iconTop = expandedIconTop + ((collapsedTop - expandedIconTop) * progress);
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10 + (15 * progress),
          sigmaY: 10 + (15 * progress),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4 * progress),
                Colors.black.withOpacity(0.1 * progress),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Back Button (always top-left)
              Positioned(
                top: collapsedTop,
                left: size.width * 0.05,
                child: LibraryBackButton(onTap: onBack),
              ),
              
              // Morphing Icon
              Positioned(
                top: iconTop,
                left: iconLeft,
                child: Hero(
                  tag: 'playlist_${playlist.name}',
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16 - (4 * progress)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      playlist.icon,
                      color: Colors.white,
                      size: iconSize * 0.45,
                    ),
                  ),
                ),
              ),
              
              // Title & Song Count in collapsed state (one line, right of icon)
              if (progress > 0.4)
                Positioned(
                  left: collapsedIconLeft + 36.0, // Right of collapsed icon
                  right: size.width * 0.05,
                  top: collapsedTop,
                  height: 44, // Same as back button height
                  child: Opacity(
                    opacity: (progress - 0.4) / 0.6, // Fade in during collapse
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          playlist.songCount,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Expanded Title (centered below icon when not collapsed)
              if (progress < 0.6)
                Positioned(
                  left: size.width * 0.05,
                  right: size.width * 0.05,
                  top: iconTop + iconSize + 20,
                  child: Opacity(
                    opacity: 1 - (progress / 0.6),
                    child: Column(
                      children: [
                        Text(
                          playlist.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlist.songCount,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_PlaylistHeaderDelegate oldDelegate) {
    return oldDelegate.collapseProgress != collapseProgress;
  }
}

class _PlaylistData {
  final String name;
  final String songCount;
  final IconData icon;

  _PlaylistData(this.name, this.songCount, this.icon);
}

class _SongData {
  final String title;
  final String artist;
  final String duration;

  _SongData({required this.title, required this.artist, required this.duration});
}
