import 'track_album_model.dart';
import 'track_artist_model.dart';
import 'related_track_model.dart';

class FirebaseTrack {
  final String id;
  final String name;
  final int popularity;
  final String? previewUrl;
  final int durationMs;
  final List<String> collectedGenres;
  final int collectedYear;
  final String primaryArtistId;
  final String primaryArtistName;
  final List<RelatedTrack> relatedTracks;
  final TrackAlbum album;
  final List<TrackArtist> artists;


  FirebaseTrack({
    required this.id,
    required this.name,
    required this.popularity,
    this.previewUrl,
    required this.durationMs,
    required this.collectedGenres,
    required this.collectedYear,
    required this.primaryArtistId,
    required this.primaryArtistName,
    required this.relatedTracks,
    required this.album,
    required this.artists,
  });

  factory FirebaseTrack.fromMap(Map<String, dynamic> map) 
  {
    final relatedTracksData = map['related_tracks'] as List<dynamic>? ?? [];
    final relatedTracks = relatedTracksData
        .cast<Map<String, dynamic>>()
        .map((data) => RelatedTrack.fromMap(data))
        .toList();

    final artistsData = map['artists'] as List<dynamic>? ?? [];
    final artists = artistsData
        .cast<Map<String, dynamic>>()
        .map((data) => TrackArtist.fromMap(data))
        .toList();

    final genres = (map['collected_genres'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    return FirebaseTrack(
      id: map['id'] as String,
      name: map['name'] as String,
      popularity: map['popularity'] as int? ?? 0,
      previewUrl: map['preview_url'] as String?,
      durationMs: map['duration_ms'] as int? ?? 0,
      collectedGenres: genres,
      collectedYear: map['collected_year'] as int? ?? DateTime.now().year,
      primaryArtistId: map['primary_artist_id'] as String? ?? '',
      primaryArtistName: map['primary_artist_name'] as String? ?? 'Unknown Artist',
      relatedTracks: relatedTracks,
      album: TrackAlbum.fromMap(map),
      artists: artists,
    );
  }

  Map<String, dynamic> toMap() 
  {
    return {
      'id': id,
      'name': name,
      'popularity': popularity,
      'preview_url': previewUrl,
      'duration_ms': durationMs,
      'collected_genres': collectedGenres,
      'collected_year': collectedYear,
      'primary_artist_id': primaryArtistId,
      'primary_artist_name': primaryArtistName,
      'related_tracks': relatedTracks.map((rt) => rt.toMap()).toList(),
      'artists': artists.map((a) => a.toMap()).toList(),
      ...album.toMap(),
    };
  }

  String get artist => primaryArtistName;
  String get albumName => album.name;
  String get albumImageUrl => album.images.primary;
  String get releaseDate => album.releaseDate;
  int get duration => durationMs;
  String get albumId => album.id;
}
