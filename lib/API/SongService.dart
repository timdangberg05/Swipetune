import './SpotifyApiClient.dart';
import '../models/Track.dart';

class SongService{

  SpotifyApiClient _apiClient;
  

  SongService(this._apiClient);


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