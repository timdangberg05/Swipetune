import './SpotifyApiClient.dart';
import './Track.dart';

class SongService{

  SpotifyApiClient _apiClient; 
  

  SongService(this._apiClient);


  Future<List<Track>?> getTopTrack() async {

    Map<String, dynamic> trackMap = await _apiClient.get('/tracks/0VjIjW4GlUZAMYd2vXMi3b');

    List<dynamic> trackList = trackMap['items'];

    List<Track>? tracks = trackList.map((item) => Track.fromMap(item)).toList();

    tracks = tracks.isNotEmpty ? tracks : null;

    return tracks;
  }


}