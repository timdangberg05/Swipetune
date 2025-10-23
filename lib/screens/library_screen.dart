import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:swipetune/services/playlist_service.dart';
import '../widgets/library/library_back_button.dart';
import '../widgets/library/playlist_item.dart';
import '../widgets/library/song_item.dart';
import '../widgets/library/song_list_item.dart';
import 'package:provider/provider.dart';
import '../providers/spotify_data_provider.dart';
import '../models/playlist_model.dart';
import '../models/personal_album.dart';
import '../models/firebasemodels/firebase_track_model.dart';
import '../services/library_service.dart';
import 'package:swipetune/widgets/library/compact_collection_card.dart';

class LibraryScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final AnimationController? libraryMorphController;
  final ValueNotifier<bool>? isDetailViewNotifier; // <-- NEU

  const LibraryScreen({
    super.key, 
    this.scrollController, 
    this.libraryMorphController,
    this.isDetailViewNotifier // <-- NEU
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum LibraryDetailState { none, likedSongs, spotifyPlaylist, localAlbum }

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  LibraryDetailState _detailState = LibraryDetailState.none;
  dynamic _selectedItem; // Speichert das PlaylistModel, PersonalAlbum oder "likedSongs"

  // Der alte _morphController wird durch den von main_screen ersetzt
  final ScrollController _detailScrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);
  late final LibraryService libraryService = LibraryService();
  final TextEditingController _albumNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
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
    _detailScrollController.dispose();
    _scrollOffsetNotifier.dispose();
    super.dispose();
  }
  
  void _openDetailView(LibraryDetailState detailState, dynamic selectedItem) async {
    HapticFeedback.lightImpact();
    setState(() {
      _detailState = detailState;
      _selectedItem = selectedItem;
    });
    _scrollOffsetNotifier.value = 0.0;
    widget.isDetailViewNotifier?.value = true;
    widget.libraryMorphController?.forward();

    if (detailState == LibraryDetailState.spotifyPlaylist) {
      PlaylistModel playlist = selectedItem;
      if (playlist.playlistTracks.isEmpty) {
        final playlistService = context.read<PlaylistService>();
        final tracks = await playlistService.getPlaylistTracks(playlist.id);
        if (mounted && _selectedItem?.id == playlist.id) {
          setState(() {
            playlist.playlistTracks.addAll(tracks);
          });
        }
      }
    }
  }

  void _closeDetailView() {
    HapticFeedback.lightImpact();
    widget.isDetailViewNotifier?.value = false;
    widget.libraryMorphController?.reverse().then((_) {
      if (mounted) {
        setState(() {
          _detailState = LibraryDetailState.none;
          _selectedItem = null;
        });
      }
    });
  }

  void _createAlbumDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                    left: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                    right: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Neues Album erstellen',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24),
                        TextField(
                          controller: _albumNameController,
                          autofocus: true,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Album Name',
                            hintStyle: GoogleFonts.manrope(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  _albumNameController.clear();
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Abbrechen',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_albumNameController.text.isNotEmpty) {
                                    HapticFeedback.lightImpact();
                                    libraryService.createAlbum(_albumNameController.text);
                                    Navigator.of(context).pop();
                                    _albumNameController.clear();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Erstellen',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: _detailState != LibraryDetailState.none,
          child: AnimatedOpacity(
            opacity: _detailState == LibraryDetailState.none ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _buildMainLibraryView(context),
          ),
        ),

        if (_detailState != LibraryDetailState.none)
          _buildDetailView(context),
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
        // Sektion 1: "Meine Sammlung" Überschrift
        SliverPadding(
          padding: EdgeInsets.only(
            top: topPadding,
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: 16,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Meine Sammlung',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Sektion 2: Horizontales Karussell
        SliverToBoxAdapter(
          child: SizedBox(
            height: 165,
            child: ValueListenableBuilder<Box<PersonalAlbum>>(
              valueListenable: libraryService.getAlbumsListenable(),
              builder: (context, box, _) {
                final albums = box.values.toList();
                final likedCount = context.watch<SpotifyDataProvider>().likedTracks.length;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(left: horizontalPadding),
                  itemCount: albums.length + 2, // +2 für Liked & Create
                  itemBuilder: (context, index) {
                    // Item 1: Liked Songs
                    if (index == 0) {
                      return CompactCollectionCard(
                        title: "Liked Songs",
                        subtitle: "$likedCount Tracks",
                        type: CompactCardType.liked,
                        onTap: () => _openDetailView(LibraryDetailState.likedSongs, "likedSongs"),
                        heroTag: 'hero-liked-songs',
                      );
                    }
                    // Item 2: Create Album
                    if (index == 1) {
                      return CompactCollectionCard(
                        title: "Erstellen",
                        subtitle: "Neues Album",
                        type: CompactCardType.create,
                        onTap: () => _createAlbumDialog(context),
                        heroTag: 'hero-create-album',
                      );
                    }
                    // Rest: Eigene Alben
                    final album = albums[index - 2];
                    return CompactCollectionCard(
                      title: album.name,
                      subtitle: "${album.trackIds.length} Tracks",
                      imageUrl: album.coverImageUrl,
                      type: CompactCardType.album,
                      onTap: () => _openDetailView(LibraryDetailState.localAlbum, album),
                      heroTag: 'hero-album-${album.key}',
                    );
                  },
                );
              },
            ),
          ),
        ),
        
        // Sektion 3: "Spotify Playlists" Überschrift
        SliverPadding(
          padding: EdgeInsets.only(
            top: 32, // Mehr Abstand
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: 16,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Spotify Playlists',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Sektion 4: Vertikale Playlist (wie vorher, aber als Sliver)
        SliverPadding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: bottomPadding,
          ),
          sliver: _buildPlaylistList(), // Diese Methode bleibt gleich
        ),
      ],
    );
  }

  Widget _buildPlaylistList() {
    return Consumer<SpotifyDataProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingPlaylists && provider.userPlaylists.isEmpty) {
          // Zustand 1: Am Anfang laden
          return const SliverToBoxAdapter(
            child: Center(
              heightFactor: 5,
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (provider.playlistErrorMessage != null) {
          // Zustand 2: Fehler
          return SliverToBoxAdapter(
            child: Center(
              heightFactor: 5,
              child: Text('Error: ${provider.playlistErrorMessage}', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        if (provider.userPlaylists.isEmpty) {
          // Zustand 3: Geladen, aber leer
          return const SliverToBoxAdapter(
            child: Center(
              heightFactor: 5,
              child: Text('No Spotify Playlists found.', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        // Zustand 4: Erfolg
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final playlist = provider.userPlaylists[index];
              return PlaylistItem(
                key: ValueKey(playlist.id),
                playlist: playlist,
                onTap: () => _openDetailView(LibraryDetailState.spotifyPlaylist, playlist),
              );
            },
            childCount: provider.userPlaylists.length,
          ),
        );
      },
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final morphAnim = CurvedAnimation(
      parent: widget.libraryMorphController!,
      curve: Curves.easeInOutCubicEmphasized,
    );

    return AnimatedBuilder(
      animation: morphAnim,
      builder: (context, child) {
        final borderRadius = 24 * (1 - morphAnim.value);
        final blurAmount = 5 + (25 * morphAnim.value);
        final gradientOpacity = 0.25 * morphAnim.value;

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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(gradientOpacity),
                        Colors.black.withOpacity(gradientOpacity * 0.6),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.3, 1.0],
                    ),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: widget.libraryMorphController!,
                      curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
                    )),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: _buildDetailContent(context),
    );
  }

  Widget _buildDetailContent(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    final expandedHeight = size.height * 0.35;
    final collapsedHeight = MediaQuery.of(context).padding.top + 60.0;

    return AnimatedBuilder(
      animation: widget.libraryMorphController!,
      builder: (context, child) {
        final progress = widget.libraryMorphController!.value;

        return Consumer<SpotifyDataProvider>(
          builder: (context, provider, _) {
            final int likedCount = provider.likedTracks.length;

            return CustomScrollView(
              controller: _detailScrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _LibraryDetailHeaderDelegate(
                    minHeight: collapsedHeight,
                    maxHeight: expandedHeight,
                    detailState: _detailState,
                    selectedItem: _selectedItem,
                    onBack: _closeDetailView,
                    scrollOffsetNotifier: _scrollOffsetNotifier,
                    likedSongsCount: likedCount,
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
                sliver: _buildMasterSongList(),
              ),
            ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildMasterSongList() {
    switch (_detailState) {
      case LibraryDetailState.spotifyPlaylist:
        return _buildSongList(_selectedItem as PlaylistModel);
      case LibraryDetailState.likedSongs:
        return _buildLikedSongsList();
      case LibraryDetailState.localAlbum:
        return _buildLocalAlbumList(_selectedItem as PersonalAlbum);
      default:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text('Not implemented yet', style: TextStyle(color: Colors.white)),
          ),
        );
    }
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

  Widget _buildLikedSongsList() {
    return Selector<SpotifyDataProvider, List<FirebaseTrack>>(
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
              return SongListItem(
                key: ValueKey(track.id),
                track: track,
                index: index,
                onTap: () {}, // TODO: Implement song playback
                onShowOptions: () => _showSongOptions(context, track),
              );
            },
            childCount: tracks.length,
          ),
        );
      },
    );
  }

  Widget _buildLocalAlbumList(PersonalAlbum album) {
    // Annahme: Alben können nur Tracks enthalten, die auch geliked wurden.
    // Wir holen uns die volle Track-Info aus dem SpotifyDataProvider.
    final allLikedTracks = context.watch<SpotifyDataProvider>().likedTracks;
    
    final albumTracks = allLikedTracks.where((track) {
      return album.trackIds.contains(track.id);
    }).toList();

    if (albumTracks.isEmpty) {
      // WICHTIG: Fixt den Scroll-Bug
      return const SliverFillRemaining(
        hasScrollBody: false, 
        child: Center(
          child: Text(
            'Füge Songs zu diesem Album hinzu', 
            style: TextStyle(color: Colors.white54)
          ),
        ),
      );
    }

    // Wenn Tracks vorhanden sind, zeige die Liste
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = albumTracks[index];
          return SongListItem(
            key: ValueKey(track.id),
            track: track,
            index: index,
            onTap: () {}, // TODO: Implement song playback
            onShowOptions: () => _showSongOptions(context, track),
          );
        },
        childCount: albumTracks.length,
      ),
    );
  }

  void _showSongOptions(BuildContext context, FirebaseTrack track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                    left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                    right: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              track.name,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              track.artist,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      
                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section 1: Add to Personal Albums
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                                child: Text(
                                  'Zu Album hinzufügen',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<Box<PersonalAlbum>>(
                                valueListenable: libraryService.getAlbumsListenable(),
                                builder: (context, box, _) {
                                  final albums = box.values.toList();
                                  if (albums.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      child: Text(
                                        'Keine eigenen Alben vorhanden',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: albums.map((album) {
                                      return _buildOptionTile(
                                        icon: Icons.album,
                                        title: album.name,
                                        subtitle: '${album.trackIds.length} Tracks',
                                        onTap: () {
                                          libraryService.addTrackToAlbum(
                                            album.key.toString(),
                                            track.id,
                                          );
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added to ${album.name}'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.green.withOpacity(0.9),
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 8),
                              Divider(color: Colors.white.withOpacity(0.1), height: 1),
                              const SizedBox(height: 8),
                              
                              // Section 2: Add to Spotify Playlists
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                                child: Text(
                                  'Zu Spotify-Playlist hinzufügen',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Consumer<SpotifyDataProvider>(
                                builder: (context, provider, _) {
                                  final playlists = provider.userPlaylists;
                                  if (playlists.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      child: Text(
                                        'Keine Spotify-Playlists verfügbar',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: playlists.map((playlist) {
                                      return _buildOptionTile(
                                        icon: Icons.playlist_add,
                                        title: playlist.name,
                                        subtitle: '${playlist.trackCount} Tracks',
                                        onTap: () async {
                                          // Add to Spotify playlist
                                          final playlistService = context.read<PlaylistService>();
                                          try {
                                            await playlistService.addTracksToPlaylist(
                                              playlist.id,
                                              ['spotify:track:${track.id}'],
                                            );
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Added to ${playlist.name}'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: Colors.green.withOpacity(0.9),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: Could not add track'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: Colors.red.withOpacity(0.9),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryDetailHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final LibraryDetailState detailState;
  final dynamic selectedItem;
  final VoidCallback onBack;
  final ValueNotifier<double> scrollOffsetNotifier;
  final int likedSongsCount;

  _LibraryDetailHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.detailState,
    required this.selectedItem,
    required this.onBack,
    required this.scrollOffsetNotifier,
    this.likedSongsCount = 0,
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
          child: _LibraryDetailHeaderContent(
            progress: progress,
            detailState: detailState,
            selectedItem: selectedItem,
            onBack: onBack,
            minHeight: minHeight,
            maxHeight: maxHeight,
            likedSongsCount: likedSongsCount,
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(_LibraryDetailHeaderDelegate oldDelegate) {
    return oldDelegate.detailState != detailState ||
           oldDelegate.selectedItem != selectedItem ||
           oldDelegate.minHeight != minHeight ||
           oldDelegate.maxHeight != maxHeight;
  }
}

class _LibraryDetailHeaderContent extends StatelessWidget {
  final double progress;
  final LibraryDetailState detailState;
  final dynamic selectedItem;
  final VoidCallback onBack;
  final double minHeight;
  final double maxHeight;
  final int likedSongsCount;

  const _LibraryDetailHeaderContent({
    required this.progress,
    required this.detailState,
    required this.selectedItem,
    required this.onBack,
    required this.minHeight,
    required this.maxHeight,
    required this.likedSongsCount,
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
                
                _buildIcon(
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

  Widget _buildIcon({
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
          tag: _getHeroTag(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _buildIconChild(iconSize, borderRadius),
          ),
        ),
      ),
    );
  }

  String _getHeroTag() {
    switch (detailState) {
      case LibraryDetailState.spotifyPlaylist:
        final playlist = selectedItem as PlaylistModel;
        return 'playlist_${playlist.id}';
      case LibraryDetailState.likedSongs:
        return 'hero-liked-songs';
      case LibraryDetailState.localAlbum:
        final album = selectedItem as PersonalAlbum;
        return 'album_${album.name}';
      default:
        return 'library_detail';
    }
  }

  Widget _buildIconChild(double iconSize, double borderRadius) {
    switch (detailState) {
      case LibraryDetailState.spotifyPlaylist:
        final playlist = selectedItem as PlaylistModel;
        return playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: playlist.imageUrl!,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
                memCacheWidth: (iconSize * 2).toInt(),
                memCacheHeight: (iconSize * 2).toInt(),
                errorWidget: (_, __, ___) => _buildPlaceholder(iconSize, borderRadius),
              )
            : _buildPlaceholder(iconSize, borderRadius);
      case LibraryDetailState.likedSongs:
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFF9B51E0).withOpacity(0.7),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            Icons.favorite,
            color: Colors.white,
            size: iconSize * 0.6,
          ),
        );
      case LibraryDetailState.localAlbum:
        final album = selectedItem as PersonalAlbum;
        return album.coverImageUrl != null
            ? CachedNetworkImage(
                imageUrl: album.coverImageUrl!,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
                memCacheWidth: (iconSize * 2).toInt(),
                memCacheHeight: (iconSize * 2).toInt(),
                errorWidget: (_, __, ___) => _buildPlaceholder(iconSize, borderRadius),
              )
            : _buildPlaceholder(iconSize, borderRadius);
      default:
        return _buildPlaceholder(iconSize, borderRadius);
    }
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
    final (name, count) = _getTitleData();

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
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$count tracks',
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
    final (name, count) = _getTitleData();

    return Positioned(
      left: size.width * 0.05,
      right: size.width * 0.05,
      top: iconTop + iconSize + 20,
      child: Opacity(
        opacity: opacity,
        child: Column(
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count tracks',
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

  (String, int) _getTitleData() {
    switch (detailState) {
      case LibraryDetailState.spotifyPlaylist:
        final playlist = selectedItem as PlaylistModel;
        return (playlist.name, playlist.trackCount);
      case LibraryDetailState.likedSongs:
        return ('Liked Songs', likedSongsCount);
      case LibraryDetailState.localAlbum:
        final album = selectedItem as PersonalAlbum;
        return (album.name, album.trackIds.length);
      default:
        return ('Unknown', 0);
    }
  }
}
