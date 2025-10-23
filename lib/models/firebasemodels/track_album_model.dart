import 'album_images_model.dart';
import 'track_artist_model.dart';

class TrackAlbum 
{
  final String id;
  final String name;
  final String releaseDate;
  final String releaseDatePrecision;
  final int totalTracks;
  final String type;
  final AlbumImages images;
  final List<TrackArtist> artists;

  TrackAlbum({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.releaseDatePrecision,
    required this.totalTracks,
    required this.type,
    required this.images,
    required this.artists,
  });

  factory TrackAlbum.fromMap(Map<String, dynamic> map) 
  {
    final artistsData = map['album_artists'] as List<dynamic>? ?? [];
    final artists = artistsData
        .cast<Map<String, dynamic>>()
        .map((data) => TrackArtist.fromMap(data))
        .toList();

    return TrackAlbum(
      id: map['album_id'] as String? ?? '',
      name: map['album_name'] as String? ?? 'Unknown Album',
      releaseDate: map['album_release_date'] as String? ?? '',
      releaseDatePrecision: map['album_release_date_precision'] as String? ?? 'day',
      totalTracks: map['album_total_tracks'] as int? ?? 0,
      type: map['album_type'] as String? ?? 'album',
      images: AlbumImages.fromMap(map['album_images'] as Map<String, dynamic>? ?? {}),
      artists: artists,
    );
  }

  Map<String, dynamic> toMap() 
  {
    return {
      'album_id': id,
      'album_name': name,
      'album_release_date': releaseDate,
      'album_release_date_precision': releaseDatePrecision,
      'album_total_tracks': totalTracks,
      'album_type': type,
      'album_images': images.toMap(),
      'album_artists': artists.map((a) => a.toMap()).toList(),
    };
  }
}
