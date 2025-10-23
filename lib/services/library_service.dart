import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipetune/models/personal_album.dart';

class LibraryService {
  static const String _boxName = 'personal_albums';

  Future<Box<PersonalAlbum>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<PersonalAlbum>(_boxName);
    }
    return Hive.box<PersonalAlbum>(_boxName);
  }

  Future<void> createAlbum(String name) async {
    final box = await _getBox();
    final album = PersonalAlbum(name: name);
    await box.add(album);
  }

  ValueListenable<Box<PersonalAlbum>> getAlbumsListenable() {
    return Hive.box<PersonalAlbum>(_boxName).listenable();
  }

  Future<void> addTrackToAlbum(String albumKey, String trackId) async {
    final box = await _getBox();
    final album = box.get(int.parse(albumKey));
    if (album != null && !album.trackIds.contains(trackId)) {
      album.trackIds.add(trackId);
      await album.save();
    }
  }

  Future<void> removeTrackFromAlbum(String albumKey, String trackId) async {
    final box = await _getBox();
    final album = box.get(int.parse(albumKey));
    if (album != null) {
      album.trackIds.remove(trackId);
      await album.save();
    }
  }

  PersonalAlbum? getAlbum(String key) {
    final box = Hive.box<PersonalAlbum>(_boxName);
    return box.get(int.parse(key));
  }
}
