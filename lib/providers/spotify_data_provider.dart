import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';
import 'package:swipetune/models/playlist_model.dart';
import 'package:swipetune/services/discovery_service.dart';
import 'package:swipetune/services/playlist_service.dart';
import 'package:swipetune/utils/local_preferences_storage.dart';
import '../API/SongService.dart';

enum SwipeAction { like, dislike }
class SpotifyDataProvider extends ChangeNotifier {
  final SongService _songService;
  final PlaylistService _playlistSerivce;
  final DiscoveryService _discoveryService;
  final LocalPreferenceStorage _localPreferenceStorage;


  List<FirebaseTrack> _tracks = [];
  List<FirebaseTrack> _likedTracks = [];
  List<FirebaseTrack> _dislikedTracks = [];
  List<PlaylistModel> _userPlaylists = [];

  

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPrefetching = false;
  String?  _swipTunePlaylistId;
  bool _isLoadingPlaylist = false;
  bool _isLoadingPlaylistTracks = false;

  List<FirebaseTrack> get tracks => _tracks;
  List<FirebaseTrack> get likedTracks => _likedTracks;
  List<FirebaseTrack> get dislikedTracks => _dislikedTracks;

  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FirebaseTrack? get currentTrack => _currentIndex < _tracks.length ? _tracks[_currentIndex] : null;
  int get likedCount => _likedTracks.length;
  int get dislikedCount => _dislikedTracks.length;
  bool get isPrefetching => _isPrefetching;
  List<PlaylistModel> get userPlaylists => _userPlaylists;
  String? get swipTunePlaylistId => _swipTunePlaylistId;
  bool get isLoadingPlaylists => _isLoadingPlaylist;
  bool get isLoadingPlaylistTracks => _isLoadingPlaylistTracks;

  late final ValueNotifier<SwipeAction?> _swipeActionNotifier;
  final ValueNotifier<Offset> dragOffsetNotifier = ValueNotifier(Offset.zero);
  ValueNotifier<SwipeAction?> get swipeActionNotifier => _swipeActionNotifier;

  SpotifyDataProvider(this._songService, this._playlistSerivce,this._discoveryService, this._localPreferenceStorage)
  {
    _swipeActionNotifier = ValueNotifier<SwipeAction?>(null);
  }

  // Future<void> loadTracks() async
  // {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();
  //   try
  //   {
  //     _tracks = await _songService.getTopTracks();
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  //   catch(e)
  //   {
  //     _errorMessage = 'Fehler beim Laden $e';
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  Future<void> loadUserPlaylists() async {
  _isLoadingPlaylist = true;
  notifyListeners();

  try {
    if (_userPlaylists.isEmpty) {
      _userPlaylists = await _playlistSerivce.getUserPlaylists();
    }
    
    _isLoadingPlaylist = false;
    notifyListeners();
    loadAllPlaylistTracksInBackground();
  } catch (e) {
    _isLoadingPlaylist = false;
    notifyListeners();
  }
}
Future<void> loadAllPlaylistTracksInBackground() async 
{
    if (_isLoadingPlaylistTracks) return;
    
    _isLoadingPlaylistTracks = true;
    print('=== BACKGROUND LOADING TRACKS ===');

    try {
      final futures = _userPlaylists.map((playlist) async {
        if (playlist.playlistTracks.isEmpty) {
          final tracks = await _playlistSerivce.getPlaylistTracks(playlist.id);
          playlist.playlistTracks.addAll(tracks);
          print('✓ Loaded: ${playlist.name} (${tracks.length} tracks)');
          notifyListeners();
        }
      }).toList();

      await Future.wait(futures);
      print('✓ All tracks loaded!');
    } catch (e) {
      print('❌ Background loading error: $e');
    } finally {
      _isLoadingPlaylistTracks = false;
      notifyListeners();
    }
  }



  Future<void> createLikeSongsPlaylist(String userId) async 
  {
    try
    {
      final existingPlaylist = _userPlaylists.firstWhere((p) => p.name == 'Swipetunes Likes',orElse: () => null as PlaylistModel);
      if(existingPlaylist != null)
      {
        _swipTunePlaylistId = existingPlaylist.id;
        return; 
      }
      final playlist = await _playlistSerivce.createPlaylist(userId, 'Swipetunes Likes', description: 'Your liked Tracks from Swipetunes', isPublic: false);
      _swipTunePlaylistId = playlist.id;
      _userPlaylists.add(playlist);

      print('✓ Created playlist: ${playlist.id}');
      notifyListeners();
    }
    catch(e)
    {
      print('❌ Error creating playlist: $e');
      rethrow;
    }
  }

  Future<void> syncLikedTracksToPlaylist() async
  {
    if(_swipTunePlaylistId == null)
    {
      return;
    }
    if(_likedTracks.isEmpty)
    {
      return;
    }
    try
    {
      final trackUris = _likedTracks.map((track) => 'spotify:track:${track.id}').toList();
      await _playlistSerivce.addTracksToPlaylist(_swipTunePlaylistId!, trackUris);
      notifyListeners();
    }
    catch(e)
    {
      print('❌ Error syncing tracks: $e');
      rethrow;
    }
  }

  Future<void> clearLikedTracksFromPlaylist() async
  {
    if(_swipTunePlaylistId == null)
    {
      return;
    }
    try
    {
      final currentTracks = await _playlistSerivce.getPlaylistTracks(_swipTunePlaylistId!);
      if(currentTracks.isEmpty)
      {
        return;
      }
      final trackUris = currentTracks.map((track) => 'spotify:track:${track.id}').toList();
      await _playlistSerivce.removeTracksFromPlaylist(_swipTunePlaylistId!, trackUris);
      notifyListeners();
    }
    catch(e)
    {
      print('❌ Error clearing playlist: $e');
      rethrow;
    }
  }

  // Future<void> loadDiscoveryTracks() async
  // {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();

  //   try
  //   {
  //     _tracks = await _songService.getDiscoveryTracks();
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  //   catch(e)
  //   {
  //     print('Fehler $e');
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> loadDiscoveryTracks() async
  {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try
    {
      _tracks = await _discoveryService.getDiscoveryFeed(batchSize: 50);
      _isLoading = false;
      notifyListeners();
    }
    catch(e)
    {
      _errorMessage = 'Fehler beim laden: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> prefetchMoreTracks() async
  // {
  //   if(_isPrefetching) return;
  //   _isPrefetching = true;
  //   notifyListeners();

  //   try
  //   {
  //     final prefetchedTracks = await _songService.getDiscoveryTracks();
  //     _tracks.addAll(prefetchedTracks);
  //     print('prefetched more Tracks');
  //     _isPrefetching = false;
  //     notifyListeners();
  //   }
  //   catch(e)
  //   {
  //     _isPrefetching = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> prefetchMoreTracks() async
  {
    if(_isLoading) return;
    _isPrefetching = true;
    notifyListeners();
    try
    {
      final prefetchedTracks = await _discoveryService.getDiscoveryFeed(batchSize: 50);
      _tracks.addAll(prefetchedTracks);
      print('✓ Prefetched ${prefetchedTracks.length} tracks');
      _isPrefetching = false;
      notifyListeners();
    }
    catch(e)
    {
      _isPrefetching = false;
      notifyListeners();
    }
  }

  void checkForPrefetching()
  {
    int remaningTracks = _tracks.length - _currentIndex;
    if(remaningTracks <= 30 && !_isPrefetching && !_isLoading) prefetchMoreTracks();
  }

  Future<void> likeTrack() async
  {
    if(currentTrack == null) return;
    final track = currentTrack!;
    _likedTracks.add(track);
    _swipeActionNotifier.value =SwipeAction.like;
    await updatePreferencesAfterLike(track);
    nextTrack();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), () {
      _swipeActionNotifier.value = null;
    });
  }
  Future<void> updatePreferencesAfterLike(FirebaseTrack track) async 
  {
    try {
      final prefs = await _localPreferenceStorage.getUserPreference();
      final updatedLikedTracks = Set<String>.from(prefs.likedTracks)..add(track.id);
      final updatedSwipeHistory = List<String>.from(prefs.swipeHistory)..add(track.id);
      final updatedLikedArtists = Set<String>.from(prefs.likedArtists)..add(track.primaryArtistId);
      final updatedLikedGenres = Set<String>.from(prefs.likedGenres);
      final updatedTrackLikeCounts = Map<String, int>.from(prefs.trackLikeCounts);
      final updatedArtistLikeCounts = Map<String, int>.from(prefs.artistLikeCounts);
      final updatedGenreLikeCounts = Map<String, int>.from(prefs.genreLikeCounts);

      if (updatedSwipeHistory.length > 200) 
      {
      updatedSwipeHistory.removeRange(0, updatedSwipeHistory.length - 200);
      }
      
      updatedTrackLikeCounts[track.id] = (updatedTrackLikeCounts[track.id] ?? 0) + 1;
      updatedArtistLikeCounts[track.primaryArtistId] = (updatedArtistLikeCounts[track.primaryArtistId] ?? 0) + 1;
      
      for (final genre in track.collectedGenres) {
        updatedGenreLikeCounts[genre] = (updatedGenreLikeCounts[genre] ?? 0) + 1;
        updatedLikedGenres.add(genre);
        for (final genre in track.collectedGenres) {
          if (!prefs.expandedGenres.containsKey(genre)) {
            _discoveryService.expandGenreInBackground(genre);
            print('🌱 Started background expansion for: $genre');
          }
        }

        
      }
      final updatedPrefs = prefs.copyWith(
        likedTracks: updatedLikedTracks,
        swipeHistory: updatedSwipeHistory,
        trackLikeCounts: updatedTrackLikeCounts,
        artistLikeCounts: updatedArtistLikeCounts,
        genreLikeCounts: updatedGenreLikeCounts,
        likedArtists: updatedLikedArtists,
        likedGenres: updatedLikedGenres,
        lastSwipeTime: DateTime.now(),
      );
      
      await _localPreferenceStorage.updateUserPreference(updatedPrefs);
      print('✅ LIKE saved: ${updatedPrefs.totalSwipes} total swipes');
    } catch (e) {
      print('❌ Error updating preferences after like: $e');
    }
  }


  Future<void> dislikeTrack() async
  {
    if(currentTrack == null) return;
    final track = currentTrack!;
    _dislikedTracks.add(track);
    _swipeActionNotifier.value = SwipeAction.dislike;
    await updatePreferencesAfterDislike(track);
    nextTrack();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), () {
      _swipeActionNotifier.value = null;
    });
  }

  Future<void> updatePreferencesAfterDislike(FirebaseTrack track) async 
  {
    try {
      final prefs = await _localPreferenceStorage.getUserPreference();
      final updatedDislikedTracks = Set<String>.from(prefs.dislikedTracks)..add(track.id);
      final updatedSwipeHistory = List<String>.from(prefs.swipeHistory)..add(track.id);
      final updatedDislikedArtists = Set<String>.from(prefs.dislikedArtists)..add(track.primaryArtistId);
      final updatedDislikedGenres = Set<String>.from(prefs.dislikedGenres);
      final updatedTrackDislikeCounts = Map<String, int>.from(prefs.trackDislikeCounts);
      final updatedArtistDislikeCounts = Map<String, int>.from(prefs.artistDislikeCounts);
      final updatedGenreDislikeCounts = Map<String, int>.from(prefs.genreDislikeCounts);

      if (updatedSwipeHistory.length > 200) 
      {
        updatedSwipeHistory.removeRange(0, updatedSwipeHistory.length - 200);
      }
      
      updatedTrackDislikeCounts[track.id] = (updatedTrackDislikeCounts[track.id] ?? 0) + 1;
      updatedArtistDislikeCounts[track.primaryArtistId] = (updatedArtistDislikeCounts[track.primaryArtistId] ?? 0) + 1;
      
      for (final genre in track.collectedGenres) {
        updatedGenreDislikeCounts[genre] = (updatedGenreDislikeCounts[genre] ?? 0) + 1;
        updatedDislikedGenres.add(genre);
      }
      final updatedPrefs = prefs.copyWith(
        dislikedTracks: updatedDislikedTracks,
        swipeHistory: updatedSwipeHistory,
        trackDislikeCounts: updatedTrackDislikeCounts,
        artistDislikeCounts: updatedArtistDislikeCounts,
        genreDislikeCounts: updatedGenreDislikeCounts,
        dislikedArtists: updatedDislikedArtists,
        dislikedGenres: updatedDislikedGenres,
        lastSwipeTime: DateTime.now(),
      );
      await _localPreferenceStorage.updateUserPreference(updatedPrefs);
      print('✅ DISLIKE saved: ${updatedPrefs.totalSwipes} total swipes');
    } catch (e) {
      print('❌ Error updating preferences after dislike: $e');
    }
  }


  void nextTrack()
  {
    if(currentIndex < _tracks.length -1)
    {
      _currentIndex ++;
    }
    else
    {
      _currentIndex = 0;
    }
    checkForPrefetching();
    notifyListeners();
  }

  void previousTrack()
  {
    if(_currentIndex > 0)
    {
      _currentIndex--;
      notifyListeners();
    }
  }

  void undoLastAction()
  {
    if(_likedTracks.isNotEmpty)
    {
      _likedTracks.removeLast();
      previousTrack();
      notifyListeners();
    }
    else if (_dislikedTracks.isNotEmpty)
    {
      _dislikedTracks.removeLast();
      previousTrack();
      notifyListeners();
    }
  }
  
  Future<void> reload() async
  {
    _currentIndex = 0;
    _likedTracks.clear();
    _dislikedTracks.clear();
    await loadDiscoveryTracks();
  }

  void clear()
  {
    _likedTracks.clear();
    _dislikedTracks.clear();
    _currentIndex = 0;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }
}