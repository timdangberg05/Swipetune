import 'package:just_audio/just_audio.dart';
import 'package:swipetune/API/SongService.dart';
import 'package:swipetune/API/SpotifyApiClient.dart';
import 'package:swipetune/models/Track.dart';


class Preview{
  
  static final SpotifyApiClient apiClient = SpotifyApiClient();
  static late final SongService songService;
  static final player = AudioPlayer();
  static List<Track> trackBuffer = [];

  Preview._();

  static void initPreview(Track track)async {
    
    songService = SongService(apiClient);

    String? previewUrl = await songService.getDeezerPreviewUrl(track);
    
    if(previewUrl != null){
      player.setUrl(previewUrl);
    }
  }

  static void refreshPlayer(){
    
  }

}