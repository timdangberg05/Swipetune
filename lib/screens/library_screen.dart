import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipetune/models/Track.dart';
import 'package:swipetune/services/playlist_service.dart';
import '../widgets/library/library_back_button.dart';
import '../widgets/library/playlist_item.dart';
import '../widgets/library/song_item.dart';
import 'package:provider/provider.dart';
import '../providers/spotify_data_provider.dart';
import '../models/playlist_model.dart';



class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});



  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}



class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  PlaylistModel? _selectedPlaylist;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotifyDataProvider>().loadUserPlaylists();
    });
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
  
  void _openPlaylist(PlaylistModel playlist) async {
    setState(() {
      _selectedPlaylist = playlist;
      _scrollOffset = 0.0;
    });
    _morphController.forward();
    if(playlist.playlistTracks.isEmpty)
    {
      final playlistService = context.read<PlaylistService>();
      final tracks = await playlistService.getPlaylistTracks(playlist.id);
      setState(() {
        playlist.playlistTracks.addAll(tracks);
      });
    }
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
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    
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
                if (playlists.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                final playlist = playlists[index];
                return PlaylistItem(
                  playlist: playlist,
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



  Widget _buildPlaylistDetailView(BuildContext context, PlaylistModel playlist) {
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



  Widget _buildDetailContent(BuildContext context, PlaylistModel playlist, double progress) {
    final size = MediaQuery.of(context).size;
    final songs = _selectedPlaylist!.playlistTracks;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    
    final collapseProgress = (_scrollOffset / 150).clamp(0.0, 1.0);
    final expandedHeight = size.height * 0.35;
    final collapsedHeight = MediaQuery.of(context).padding.top + 60.0;
    
    return CustomScrollView(
      controller: _detailScrollController,
      slivers: [
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
                  final track = songs[index];
                  return SongItem(
                    track: track,
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



  List<PlaylistModel> _getPlaylists() {
    final provider = context.watch<SpotifyDataProvider>();
    return provider.userPlaylists;
  }
}



class _PlaylistHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final PlaylistModel playlist;
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
    
    final collapsedTop = safeTop + 16.0;
    final backButtonWidth = size.width * 0.05 + 44.0;
    
    final iconSize = 120 - (92 * progress);
    
    final expandedIconLeft = (size.width - 120) / 2;
    final collapsedIconLeft = backButtonWidth + 8.0;
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
              Positioned(
                top: collapsedTop,
                left: size.width * 0.05,
                child: LibraryBackButton(onTap: onBack),
              ),
              
              Positioned(
                top: iconTop,
                left: iconLeft,
                child: Hero(
                  tag: 'playlist_${playlist.name}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16 - (4 * progress)),
                    child: playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: playlist.imageUrl!,
                            width: iconSize,
                            height: iconSize,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
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
                                Icons.library_music,
                                color: Colors.white,
                                size: iconSize * 0.45,
                              ),
                            ),
                          )
                        : Container(
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
                              Icons.library_music,
                              color: Colors.white,
                              size: iconSize * 0.45,
                            ),
                          ),
                  ),
                ),
              ),
              
              if (progress > 0.4)
                Positioned(
                  left: collapsedIconLeft + 36.0,
                  right: size.width * 0.05,
                  top: collapsedTop,
                  height: 44,
                  child: Opacity(
                    opacity: (progress - 0.4) / 0.6,
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
                          '${playlist.trackCount} tracks',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
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
                          '${playlist.trackCount} tracks',
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
