import 'package:just_audio/just_audio.dart';
import 'package:swipetune/services/SongService.dart';
import 'package:swipetune/models/Track.dart';


class Preview{
  
  final player = AudioPlayer();
  late SongService songService;

  Preview(this.songService);

  void playPreview()async {
    
    /* final List<Track> tracks = await songService.getSearchResults('Slipknot');
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



    } */
    player.setUrl("https://cdnt-preview.dzcdn.net/api/1/1/0/7/1/0/071903d9430ded2ec139793ad3e9c09d.mp3?hdnea=exp=1761032455~acl=/api/1/1/0/7/1/0/071903d9430ded2ec139793ad3e9c09d.mp3*~data=user_id=0,application_id=42~hmac=c2f98f4cbd49d2255e49a7c9088837f170ff242b42634431e6e0eb9e8d3f497e");
    player.play();
    
  }


}