

class Track{


  final String id;
  final String name;
  final String artist;

  Track({required this.id, required this.name, required this. artist});

  Track.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      name = map['name'],
      artist = map['artists'][0]['name'];


      
}