import 'package:flutter/foundation.dart';
import 'package:swipetune/models/playlist_model.dart';
import 'package:swipetune/services/playlist_service.dart';
import '../API/SongService.dart';
import '../models/Track.dart';

class SpotifyDataProvider extends ChangeNotifier {
  final SongService _songService;
  final PlaylistService _playlistSerivce;

  List<Track> _tracks = [];
  List<Track> _likedTracks = [];
  List<Track> _dislikedTracks = [];
  List<PlaylistModel> _userPlaylists = [];



  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPrefetching = false;
  String?  _swipTunePlaylistId;
  bool _isLoadingPlaylist = false;

  List<Track> get tracks => _tracks;
  List<Track> get likedTracks => _likedTracks;
  List<Track> get dislikedTracks => _dislikedTracks;

  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Track? get currentTrack => _currentIndex < _tracks.length ? _tracks[_currentIndex] : null;
  int get likedCount => _likedTracks.length;
  int get dislikedCount => _dislikedTracks.length;
  bool get isPrefetching => _isPrefetching;
  List<PlaylistModel> get userPlaylists => _userPlaylists;
  String? get swipTunePlaylistId => _swipTunePlaylistId;
  bool get isLoadingPlaylists => _isLoadingPlaylist;

  SpotifyDataProvider(this._songService, this._playlistSerivce);

  Future<void> loadTracks() async
  {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try
    {
      _tracks = await _songService.getTopTracks();
      _isLoading = false;
      notifyListeners();
    }
    catch(e)
    {
      _errorMessage = 'Fehler beim Laden $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> loadUserPlaylists() async
  {
    _isLoadingPlaylist = true;
    notifyListeners();

    try
    {
      _userPlaylists = await _playlistSerivce.getUserPlaylists();
      // for(var playlist in _userPlaylists)
      // {
      //   playlist.playlistTracks.clear();
      //   final playlistTracks = await _playlistSerivce.getPlaylistTracks(playlist.id);
      //   playlist.playlistTracks.addAll(playlistTracks);
      // }
      _isLoadingPlaylist = false;
      notifyListeners();
    }
    catch(e)
    {
      _isLoadingPlaylist = false;
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

  Future<void> loadDiscoveryTracks() async
  {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try
    {
      _tracks = await _songService.getDiscoveryTracks();
      _isLoading = false;
      notifyListeners();
    }
    catch(e)
    {
      print('Fehler $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> prefetchMoreTracks() async
  {
    if(_isPrefetching) return;
    _isPrefetching = true;
    notifyListeners();

    try
    {
      final prefetchedTracks = await _songService.getDiscoveryTracks();
      _tracks.addAll(prefetchedTracks);
      print('prefetched more Tracks');
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

  void likeTrack()
  {
    if(currentTrack == null) return;
    _likedTracks.add(_tracks[currentIndex]);
    nextTrack();
    notifyListeners();
  }

  void dislikeTrack()
  {
    if(currentTrack == null) return;
    _dislikedTracks.add(_tracks[currentIndex]);
    nextTrack();
    notifyListeners();
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