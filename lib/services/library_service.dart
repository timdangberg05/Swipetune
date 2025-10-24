import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipetune/models/personal_album.dart';
import 'package:swipetune/services/spotify_api_service.dart';

class LibraryService {
  static const String _boxName = 'personal_albums';
  final SpotifyApiService _spotifyApiService = SpotifyApiService();

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

      // Mark for sync if enabled
      await markTrackChangesInAlbum(albumKey);
    }
  }

  Future<void> removeTrackFromAlbum(String albumKey, String trackId) async {
    final box = await _getBox();
    final album = box.get(int.parse(albumKey));
    if (album != null) {
      album.trackIds.remove(trackId);
      await album.save();

      // Mark for sync if enabled
      await markTrackChangesInAlbum(albumKey);
    }
  }

  PersonalAlbum? getAlbum(String key) {
    final box = Hive.box<PersonalAlbum>(_boxName);
    return box.get(int.parse(key));
  }

  Future<void> enableSpotifySync(String albumKey) async {
    final box = await _getBox();
    final album = box.get(int.parse(albumKey));
    if (album != null && !album.syncEnabled) {
      album.syncEnabled = true;
      album.needsSync = true;
      await album.save();
      print('Enabled Spotify sync for album: ${album.name}');
    }
  }

  Future<void> disableSpotifySync(String albumKey) async {
    final box = await _getBox();
    final album = box.get(int.parse(albumKey));
    if (album != null && album.syncEnabled) {
      album.syncEnabled = false;
      album.needsSync = false;
      await album.save();
      print('Disabled Spotify sync for album: ${album.name}');
    }
  }

  Future<void> syncAlbumToSpotify(String albumKey) async {
    final box = await _getBox();
    final album = box.get(int.parse(albumKey));
    if (album != null && album.syncEnabled) {
      try {
        await _spotifyApiService.syncAlbumToSpotify(album);

        // Reload from box in case the playlist ID was updated during sync
        final updatedAlbum = box.get(int.parse(albumKey));
        if (updatedAlbum != null) {
          print('Successfully synced album: ${updatedAlbum.name}');
        }
      } catch (e) {
        print('Error syncing album ${album.name}: $e');
        // Check if this was a recovery case (playlist deleted)
        if (e.toString().contains('Playlist') && e.toString().contains('not found')) {
          print('Playlist was deleted - will recreate on next sync attempt');
        } else {
          rethrow;
        }
      }
    } else if (album != null && !album.syncEnabled) {
      print('Album ${album.name} has sync disabled, enabling first...');
      await enableSpotifySync(albumKey);
      await syncAlbumToSpotify(albumKey); // Recursive call after enabling sync
    } else {
      print('Album not found for: $albumKey');
    }
  }

  Future<void> syncAllAlbumsToSpotify() async {
    final box = await _getBox();
    final albums = box.values.where((album) => album.syncEnabled && album.needsSync).toList();

    print('Found ${albums.length} albums that need syncing');

    for (final album in albums) {
      try {
        await _spotifyApiService.syncAlbumToSpotify(album);
        print('Successfully synced album: ${album.name}');
      } catch (e) {
        print('Error syncing album ${album.name}: $e');
        // Continue with other albums even if one fails
      }
    }
  }

  Future<bool> isAlbumSynced(String albumKey) async {
    final album = getAlbum(albumKey);
    if (album == null) return false;

    if (album.spotifyPlaylistId == null) return false;

    // Check if the Spotify playlist still exists and is accessible
    return await _spotifyApiService.isPlaylistAccessible(album.spotifyPlaylistId!);
  }

  Future<List<PersonalAlbum>> getAlbumsNeedingSync() async {
    final box = await _getBox();
    return box.values.where((album) => album.syncEnabled && album.needsSync).toList();
  }

  Future<void> markTrackChangesInAlbum(String albumKey) async {
    final box = await _getBox();
    final album = box.get(int.parse(albumKey));
    if (album != null && album.syncEnabled) {
      album.needsSync = true;
      await album.save();
      print('Marked album ${album.name} as needing sync due to track changes');
    }
  }

  Future<List<PersonalAlbum>> getSyncedAlbums() async {
    final box = await _getBox();
    return box.values.where((album) => album.syncEnabled).toList();
  }
}
