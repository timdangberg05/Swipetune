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

  PersonalAlbum({required this.name, this.trackIds = const [], this.coverImageUrl});
}
