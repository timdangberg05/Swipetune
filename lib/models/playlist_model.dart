import 'package:swipetune/models/Track.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int trackCount;
  final bool isPublic;
  final String owner;
  final String ownerId;
  final List<Track> playlistTracks;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.trackCount,
    required this.isPublic,
    required this.owner,
    required this.ownerId,
    this.playlistTracks = const [],
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Playlist',
      description: map['description'],
      imageUrl: (map['images'] as List?)?.isNotEmpty == true 
          ? map['images'][0]['url'] 
          : null,
      trackCount: map['tracks']?['total'] ?? 0,
      isPublic: map['public'] ?? false,
      owner: map['owner']?['display_name'] ?? 'Unknown',
      ownerId: map['owner']?['id'] ?? '',
      playlistTracks: [],
    );
  }
}
