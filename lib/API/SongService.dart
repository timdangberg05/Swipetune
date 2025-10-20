import 'dart:async';

import 'package:swipetune/models/query_state_model.dart';

import './SpotifyApiClient.dart';
import '../models/Track.dart';

class SongService{

  SpotifyApiClient _apiClient;
  

  SongService(this._apiClient);

  final List<String> _genrePool = [
    'pop', 'rock', 'indie', 'electronic', 'hip-hop',
    'r-n-b', 'jazz', 'metal', 'reggae', 'blues',
    'alternative', 'house', 'punk', 'soul', 'funk',
    'chill', 'party', 'workout', 'k-pop', 'latin', 'rap',
  ];
    final List<int> _yearPool = List.generate(
    45, 
    (index) => 2024 - index
  );
  final List<QueryStateModel> _availableQueries = [];
  final List<QueryStateModel> _usedQueries = [];
  void _initializeQueries() {
    if (_availableQueries.isNotEmpty) return;
    
    for (var genre in _genrePool) {
      for (var year in _yearPool) {
        _availableQueries.add(
          QueryStateModel(genre: genre, year: year)
        );
      }
    }
    _availableQueries.shuffle();
  }

  QueryStateModel _getNextQuery() 
  {
    _initializeQueries();
    if(_availableQueries.isEmpty)
    {
      _availableQueries.addAll(_usedQueries);
      _usedQueries.clear();
      _availableQueries.shuffle();
    }
    final query = _availableQueries.removeAt(0);
    _usedQueries.add(query);
    return query;
  }

  Future<List<Track>> searchWithQuery(QueryStateModel query) async
  {
    final queryResponse = await _apiClient.get('/search?q=${query.query}&type=track&limit=20&offset=${query.offset}&market=US');
    final tracks = (queryResponse['tracks']['items'] as List).map((item) => Track.fromMap(item)).toList();
    query.incrementOffset();
    return tracks;
  }
  Future<List> getNewReleaseAlbumIds() async
  {
    Map<String, dynamic> albumRelaseMap = await _apiClient.get('/browse/new-releases?limit=10&market=US');
    List<dynamic> albums = albumRelaseMap['albums']['items'];
    return albums.map((item) => item['id'] as String).toList();
  }

  Future<List<Track>> getAlbumTracks(String albumRealeaseId) async
  {
    Map<String, dynamic> trackMap = await _apiClient.get('/albums/$albumRealeaseId/tracks?limit=10');
    List<dynamic> albumTracks = trackMap['items'];
    List<Track> tracks = [];
    for(var item in albumTracks)
    {
      try
      {
        Map<String, dynamic> fullTrack = await _apiClient.get('/tracks/${item['id']}');
        tracks.add(Track.fromMap(fullTrack));
      }
      catch(e)
      {
        continue;
      }
    }
    return tracks;
  }

  Future<List<Track>> getDiscoveryTracks() async
  {
    List<Track> discoveryTracks = [];
    final searchParallels = List.generate(5,(_)
    {
      final query = _getNextQuery();
      return searchWithQuery(query);
    });
    final searchResults = await Future.wait(searchParallels);
    for(var tracks in searchResults)
    {
      discoveryTracks.addAll(tracks);
    }
    try
    {
      final albumIds = await getNewReleaseAlbumIds();
      final albumParallels = albumIds.map((id) => getAlbumTracks(id)).toList();
      final albumResults = await Future.wait(albumParallels);
      for(var tracks in albumResults)
      {
        discoveryTracks.addAll(tracks);
      }
    }
    catch(e)
    {
      throw Exception('$e');
    }
    discoveryTracks.shuffle();
    discoveryTracks.shuffle();
    discoveryTracks.shuffle();
    final uniqueDiscoverysTracks = <String, Track>{};
    for(var track in discoveryTracks)
    {
      uniqueDiscoverysTracks[track.id] = track;
    }
    return uniqueDiscoverysTracks.values.toList();

  }

  Future<List<Track>> getTopTracks([String? name]) async {
    Map<String, dynamic> trackMap = await _apiClient.get('/me/top/tracks');
    List<dynamic> trackList = trackMap['items'];
    List<Track> tracks = trackList.map((item) => Track.fromMap(item)).toList();
    return tracks;
  }

  Future<Track> getTrackByID(String id)async{
    Map<String, dynamic> trackMap = await _apiClient.get('/tracks/$id');
    Track track = Track.fromMap(trackMap);
    return track;
  }

  Future<List<Track>> getSearchResults(String name)async{
    Map<String, dynamic> trackMap = await _apiClient.runQuery(name);
    List<dynamic> trackList = trackMap['tracks']['items'];
    List<Track> tracks = trackList.map((item) => Track.fromMap(item)).toList();
    return tracks;
  }
}