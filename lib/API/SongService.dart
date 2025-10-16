import './SpotifyApiClient.dart';
import '../models/Track.dart';

class SongService{

  SpotifyApiClient _apiClient;
  

  SongService(this._apiClient);


  Future<List<Track>> getTopTracks() async {

    Map<String, dynamic> trackMap = await _apiClient.get('/me/top/tracks');

    List<dynamic> trackList = trackMap['items'];

    List<Track> tracks = trackList.map((item) => Track.fromMap(item)).toList();
    return tracks;
  }
}