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
  final ScrollController? scrollController;

  const LibraryScreen({super.key, this.scrollController});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  PlaylistModel? _selectedPlaylist;
  late AnimationController _morphController;
  final ScrollController _detailScrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);
  
  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _detailScrollController.addListener(_onDetailScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotifyDataProvider>().loadUserPlaylists();
    });
  }
  
  void _onDetailScroll() {
    _scrollOffsetNotifier.value = _detailScrollController.offset;
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    _detailScrollController.dispose();
    _scrollOffsetNotifier.dispose();
    super.dispose();
  }
  
  void _openPlaylist(PlaylistModel playlist) async {
    setState(() {
      _selectedPlaylist = playlist;
    });
    _scrollOffsetNotifier.value = 0.0;
    _morphController.forward();
    
    if (playlist.playlistTracks.isEmpty) {
      final playlistService = context.read<PlaylistService>();
      final tracks = await playlistService.getPlaylistTracks(playlist.id);
      if (mounted && _selectedPlaylist?.id == playlist.id) {
        setState(() {
          playlist.playlistTracks.addAll(tracks);
        });
      }
    }
  }
  
  void _closePlaylist() {
    _morphController.reverse().then((_) {
      if (mounted) {
        setState(() => _selectedPlaylist = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: _selectedPlaylist != null,
          child: AnimatedOpacity(
            opacity: _selectedPlaylist == null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _buildMainLibraryView(context),
          ),
        ),
        
        if (_selectedPlaylist != null)
          _buildPlaylistDetailView(context, _selectedPlaylist!),
      ],
    );
  }

  Widget _buildMainLibraryView(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top + 80;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    final horizontalPadding = size.width * 0.05;
    
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            top: topPadding,
            left: horizontalPadding,
            right: horizontalPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: size.width * 0.02,
                bottom: size.height * 0.015,
              ),
              child: Text(
                'Your Library',
                style: GoogleFonts.manrope(
                  fontSize: 18,
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
          sliver: _buildPlaylistList(),
        ),
      ],
    );
  }

  Widget _buildPlaylistList() {
    return Selector<SpotifyDataProvider, List<PlaylistModel>>(
      selector: (_, provider) => provider.userPlaylists,
      builder: (context, playlists, _) {
        if (playlists.isEmpty) {
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
              final playlist = playlists[index];
              return PlaylistItem(
                key: ValueKey(playlist.id),
                playlist: playlist,
                onTap: () => _openPlaylist(playlist),
              );
            },
            childCount: playlists.length,
          ),
        );
      },
    );
  }

  Widget _buildPlaylistDetailView(BuildContext context, PlaylistModel playlist) {
    final morphAnim = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    return AnimatedBuilder(
      animation: morphAnim,
      builder: (context, child) {
        final borderRadius = 24 * (1 - morphAnim.value);
        final blurAmount = 30 * morphAnim.value;
        final opacity = 0.3 * morphAnim.value;
        
        return Positioned.fill(
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurAmount,
                  sigmaY: blurAmount,
                ),
                child: Container(
                  color: Colors.black.withOpacity(opacity),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: _buildDetailContent(context, playlist),
    );
  }

  Widget _buildDetailContent(BuildContext context, PlaylistModel playlist) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    final expandedHeight = size.height * 0.35;
    final collapsedHeight = MediaQuery.of(context).padding.top + 60.0;
    
    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        final progress = _morphController.value;
        
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
                scrollOffsetNotifier: _scrollOffsetNotifier,
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
                sliver: _buildSongList(playlist),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongList(PlaylistModel playlist) {
    final songs = playlist.playlistTracks;
    
    if (songs.isEmpty) {
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
          final track = songs[index];
          return RepaintBoundary(
            child: SongItem(
              key: ValueKey(track.id),
              track: track,
              index: index,
              onTap: () {},
            ),
          );
        },
        childCount: songs.length,
      ),
    );
  }
}

class _PlaylistHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final PlaylistModel playlist;
  final VoidCallback onBack;
  final ValueNotifier<double> scrollOffsetNotifier;

  _PlaylistHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.playlist,
    required this.onBack,
    required this.scrollOffsetNotifier,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffsetNotifier,
      builder: (context, scrollOffset, child) {
        final progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);
        
        return RepaintBoundary(
          child: _HeaderContent(
            progress: progress,
            playlist: playlist,
            onBack: onBack,
            minHeight: minHeight,
            maxHeight: maxHeight,
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(_PlaylistHeaderDelegate oldDelegate) {
    return oldDelegate.playlist.id != playlist.id ||
           oldDelegate.minHeight != minHeight ||
           oldDelegate.maxHeight != maxHeight;
  }
}

class _HeaderContent extends StatelessWidget {
  final double progress;
  final PlaylistModel playlist;
  final VoidCallback onBack;
  final double minHeight;
  final double maxHeight;

  const _HeaderContent({
    required this.progress,
    required this.playlist,
    required this.onBack,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final collapsedTop = safeTop + 16.0;
    final backButtonWidth = size.width * 0.05 + 44.0;
    
    final iconSize = 120 - (92 * progress);
    final expandedIconLeft = (size.width - 120) / 2;
    final collapsedIconLeft = backButtonWidth + 8.0;
    final iconLeft = expandedIconLeft + ((collapsedIconLeft - expandedIconLeft) * progress);
    final expandedIconTop = (maxHeight - minHeight) / 2;
    final iconTop = expandedIconTop + ((collapsedTop - expandedIconTop) * progress);
    
    final blurAmount = 10 + (15 * progress);
    
    return ClipRRect(
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
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
                
                _buildPlaylistIcon(
                  iconTop: iconTop,
                  iconLeft: iconLeft,
                  iconSize: iconSize,
                  progress: progress,
                ),
                
                if (progress > 0.4)
                  _buildCollapsedTitle(
                    collapsedIconLeft: collapsedIconLeft,
                    collapsedTop: collapsedTop,
                    progress: progress,
                    size: size,
                  ),
                
                if (progress < 0.6)
                  _buildExpandedTitle(
                    iconTop: iconTop,
                    iconSize: iconSize,
                    progress: progress,
                    size: size,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistIcon({
    required double iconTop,
    required double iconLeft,
    required double iconSize,
    required double progress,
  }) {
    final borderRadius = 16 - (4 * progress);
    
    return Positioned(
      top: iconTop,
      left: iconLeft,
      child: RepaintBoundary(
        child: Hero(
          tag: 'playlist_${playlist.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: playlist.imageUrl!,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.cover,
                    memCacheWidth: (iconSize * 2).toInt(),
                    memCacheHeight: (iconSize * 2).toInt(),
                    errorWidget: (_, __, ___) => _buildPlaceholder(iconSize, borderRadius),
                  )
                : _buildPlaceholder(iconSize, borderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double iconSize, double borderRadius) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x33FFFFFF),
            Color(0x0DFFFFFF),
          ],
        ),
      ),
      child: Icon(
        Icons.library_music,
        color: Colors.white,
        size: iconSize * 0.45,
      ),
    );
  }

  Widget _buildCollapsedTitle({
    required double collapsedIconLeft,
    required double collapsedTop,
    required double progress,
    required Size size,
  }) {
    final opacity = (progress - 0.4) / 0.6;
    
    return Positioned(
      left: collapsedIconLeft + 36.0,
      right: size.width * 0.05,
      top: collapsedTop,
      height: 44,
      child: Opacity(
        opacity: opacity,
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
    );
  }

  Widget _buildExpandedTitle({
    required double iconTop,
    required double iconSize,
    required double progress,
    required Size size,
  }) {
    final opacity = 1 - (progress / 0.6);
    
    return Positioned(
      left: size.width * 0.05,
      right: size.width * 0.05,
      top: iconTop + iconSize + 20,
      child: Opacity(
        opacity: opacity,
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
    );
  }
}
