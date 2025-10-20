class Track{


  final String id;
  final String name;
  final String artist;
  final String albumImageUrl;
  final int popularity;
  final String? previewUrl;
  final int durationMs;
  final String albumName;
  final String releaseDate;
  final int duration;

  Track(
    {required this.id, 
    required this.name, 
    required this.artist, 
    required this.albumImageUrl, 
    required this.popularity, 
    required this.previewUrl,
    required this.durationMs,
    required this.albumName,
    required this.releaseDate,
    required this.duration,
    });




  Track.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      name = map['name'],
      artist = map['artists'][0]['name'],
      albumImageUrl = map['album']['images'][0]['url'],
      popularity = map['popularity'],
      previewUrl = map['preview_url'],
      durationMs = map['duration_ms'],
      albumName = map['album']['name'],
      releaseDate = map['album']['release_date'],
      duration = map['duration_ms'];
}