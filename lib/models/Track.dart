
class Track{


  final String id;
  final String name;
  final String artist;
  final String albumImageUrl;

  Track({required this.id, required this.name, required this.artist, required this.albumImageUrl});




  Track.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      name = map['name'],
      artist = map['artists'][0]['name'],
      albumImageUrl = map['album']['images'][0]['url'];
  
}