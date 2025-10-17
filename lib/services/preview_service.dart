import 'package:just_audio/just_audio.dart';
import 'package:swipetune/API/SongService.dart';
import 'package:swipetune/models/Track.dart';


class Preview{
  
  final player = AudioPlayer();
  late SongService songService;

  Preview(this.songService);

  void playPreview()async {
    
    final List<Track> tracks = await songService.getSearchResults('Slipknot');
    for(Track track in tracks){
      if(track.previewUrl != null){
        try{
          await player.setUrl(track.previewUrl!);
          player.play();
          break;
        }catch(e){
          print('Song kann nicht abgespielt werden: $e');
        }
      }else{
        continue;
      }



    }
    
    
    
  }


}