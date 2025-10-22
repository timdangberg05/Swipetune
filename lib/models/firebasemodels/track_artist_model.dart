class TrackArtist 
{
  final String id;
  final String name;
  final String? uri;
  final Map<String, String>? externalUrls;
  final List<String> genres;
  final List<String> relatedArtists;
  final int popularity;
  final int followers;

  TrackArtist({
    required this.id,
    required this.name,
    this.uri,
    this.externalUrls,
    this.genres = const [],
    this.relatedArtists = const [],
    this.popularity = 0,
    this.followers = 0,
  });

  factory TrackArtist.fromMap(Map<String, dynamic> map) 
  {
    return TrackArtist(
      id: map['id'] as String,
      name: map['name'] as String,
      uri: map['uri'] as String?,
      externalUrls: (map['external_urls'] as Map<String, dynamic>?)?.cast<String, String>(),
      genres: (map['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      relatedArtists: (map['related_artists'] as List<dynamic>?)?.cast<String>() ?? [],
      popularity: map['popularity'] as int? ?? 0,
      followers: map['followers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() 
  {
    return {
      'id': id,
      'name': name,
      if (uri != null) 'uri': uri,
      if (externalUrls != null) 'external_urls': externalUrls,
      'genres': genres,
      'related_artists': relatedArtists,
      'popularity': popularity,
      'followers': followers,
    };
  }
}
