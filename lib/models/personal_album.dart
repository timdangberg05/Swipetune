import 'package:hive/hive.dart';
part 'personal_album.g.dart';

@HiveType(typeId: 0)
class PersonalAlbum extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<String> trackIds;

  @HiveField(2)
  String? coverImageUrl;

  @HiveField(3)
  String? spotifyPlaylistId;

  @HiveField(4)
  DateTime? lastSyncDate;

  @HiveField(5)
  bool syncEnabled;

  @HiveField(6)
  bool needsSync;

  PersonalAlbum({
    required this.name,
    this.trackIds = const [],
    this.coverImageUrl,
    this.spotifyPlaylistId,
    this.lastSyncDate,
    this.syncEnabled = false,
    this.needsSync = false,
  });
}
