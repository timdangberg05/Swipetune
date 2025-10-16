import 'package:flutter/foundation.dart';
import '../homepage_songs/song.dart';
import '../API/SongService.dart';
import '../models/Track.dart';

class SpotifyDataProvider extends ChangeNotifier {
  final SongService _songService;

  List<Track> _tracks = [];
  List<Track> _likedTracks = [];
  List<Track> _dislikedTracks = [];

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  List<Track> get tracks => _tracks;
  List<Track> get likedTracks => _likedTracks;
  List<Track> get dislikedTracks => _dislikedTracks;

  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Track? get currenTrack => _currentIndex < _tracks.length ? _tracks[_currentIndex] : null;

  int get likedCount => _likedTracks.length;
  int get dislikedCount => _dislikedTracks.length;

  SpotifyDataProvider(this._songService);

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


  void likeTrack()
  {
    if(currenTrack == null) return;
    _likedTracks.add(_tracks[currentIndex]);
    nextTrack();
    notifyListeners();
  }

  void dislikeTrack()
  {
    if(currenTrack == null) return;
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
    await loadTracks();
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