import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_services.dart';
import '../API/SpotifyApiClient.dart';
import '../models/personal_album.dart';
import '../models/Track.dart';

class SpotifyApiService {
  final SpotifyApiClient _spotifyApiClient = SpotifyApiClient();

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _spotifyApiClient.get('/me');
      return response;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<String?> createSpotifyPlaylistFromAlbum(
    PersonalAlbum album,
    String userId,
  ) async {
    try {
      final playlistName = album.name;
      final description = 'Created from SwipeTune - ${DateTime.now().toString().split(' ')[0]}';

      // Create the playlist
      final playlistResponse = await _spotifyApiClient.post(
        '/users/$userId/playlists',
        body: {
          'name': playlistName,
          'description': description,
          'public': false,
        },
      );

      final playlistId = playlistResponse['id'];
      print('Created playlist: $playlistId for album: ${album.name}');

      // Add tracks to the playlist if there are any
      if (album.trackIds.isNotEmpty) {
        await _addTrackIdsToPlaylist(playlistId, album.trackIds);
      }

      return playlistId;
    } catch (e) {
      print('Error creating Spotify playlist: $e');
      return null;
    }
  }

  Future<void> syncAlbumToSpotify(PersonalAlbum album) async {
    try {
      print('🔄 Starting sync for album: ${album.name} (${album.trackIds.length} tracks)');

      if (album.spotifyPlaylistId == null) {
        // Need to create playlist first
        print('📝 Creating new Spotify playlist for album: ${album.name}');
        final userData = await getCurrentUser();
        if (userData == null) {
          throw Exception('Could not get user data for playlist creation');
        }

        final userId = userData['id'];
        final playlistId = await createSpotifyPlaylistFromAlbum(album, userId);
        if (playlistId != null) {
          album.spotifyPlaylistId = playlistId;
          album.lastSyncDate = DateTime.now();
          album.needsSync = false;
          await album.save();
          print('✅ Successfully created and synced playlist for album: ${album.name} (ID: $playlistId)');
        } else {
          throw Exception('Failed to create Spotify playlist');
        }
      } else {
        // Update existing playlist
        print('🔄 Updating existing playlist: ${album.spotifyPlaylistId}');
        await _updateSpotifyPlaylist(album);
        album.lastSyncDate = DateTime.now();
        album.needsSync = false;
        await album.save();
        print('✅ Successfully synced existing playlist for album: ${album.name}');
      }
    } catch (e) {
      print('❌ Error syncing album ${album.name} to Spotify: $e');
      // Don't rethrow - let the UI handle it and show error message
      throw e;
    }
  }

  Future<void> _updateSpotifyPlaylist(PersonalAlbum album) async {
    if (album.spotifyPlaylistId == null) return;

    try {
      // First check if playlist still exists before proceeding
      print('🔍 Checking if playlist ${album.spotifyPlaylistId} still exists...');
      if (!await isPlaylistAccessible(album.spotifyPlaylistId!)) {
        print('⚠️ Playlist ${album.spotifyPlaylistId} not found! Resetting for recreation.');
        album.spotifyPlaylistId = null;
        album.needsSync = true;
        await album.save();
        return; // Don't throw - the playlist will be recreated on next sync
      }

      // Get current tracks in the Spotify playlist
      final currentTracks = await _getPlaylistTracks(album.spotifyPlaylistId!);

      // Clear the playlist
      if (currentTracks.isNotEmpty) {
        final trackUris = currentTracks.map((track) => track.id).toList();
        await _removeTracksFromPlaylist(album.spotifyPlaylistId!, trackUris);
      }

      // Add new tracks
      if (album.trackIds.isNotEmpty) {
        await _addTrackIdsToPlaylist(album.spotifyPlaylistId!, album.trackIds);
      }
    } catch (e) {
      print('❌ Error updating Spotify playlist: $e');

      // Special handling: If the playlist was deleted mid-process (404 error), reset it
      if (e.toString().contains('Spotify API Error (404)') ||
          e.toString().contains('Resource not found')) {
        print('🔄 Resetting deleted playlist ${album.spotifyPlaylistId} for recreation');
        album.spotifyPlaylistId = null;
        album.needsSync = true;
        await album.save();
        return; // Don't rethrow - recovery handled
      }

      rethrow; // Re-throw other errors
    }
  }

  Future<List<Track>> _getPlaylistTracks(String playlistId) async {
    try {
      final response = await _spotifyApiClient.get('/playlists/$playlistId/tracks?limit=100');
      final items = response['items'] as List?;
      if (items == null) return [];

      final tracks = <Track>[];
      for (final item in items) {
        final trackData = item['track'];
        if (trackData != null) {
          try {
            final track = Track.fromMap(trackData);
            tracks.add(track);
          } catch (e) {
            print('Error parsing track: $e');
          }
        }
      }
      return tracks;
    } catch (e) {
      print('Error getting playlist tracks: $e');
      return [];
    }
  }

  Future<void> _addTrackIdsToPlaylist(String playlistId, List<String> trackIds) async {
    if (trackIds.isEmpty) return;

    print('🎵 Adding ${trackIds.length} tracks to playlist $playlistId');
    print('📋 Raw track IDs: ${trackIds.take(5).toList()}');

    // Validate playlist exists first
    if (!await isPlaylistAccessible(playlistId)) {
      throw Exception('Playlist $playlistId does not exist or is not accessible');
    }

    // Convert track IDs to Spotify URIs
    final trackUris = trackIds.map((id) {
      if (id.startsWith('spotify:track:')) {
        return id;
      }
      return 'spotify:track:$id';
    }).toList();

    print('🔗 First 5 URIs: ${trackUris.take(5).toList()}');

    // Test one track first to validate the ID format
    if (trackUris.isNotEmpty) {
      try {
        final testUri = trackUris.first;
        final trackId = testUri.replaceFirst('spotify:track:', '');
        print('🧪 Testing track ID: $trackId');
        await _spotifyApiClient.get('/tracks/$trackId');
        print('✅ Track exists: $testUri');
      } catch (e) {
        print('❌ Test track does not exist: ${trackUris.first} - Error: $e');
        // Continue anyway, maybe some tracks will work
      }
    }

    // Add tracks in batches of 100 (Spotify API limit)
    const batchSize = 100;
    for (int i = 0; i < trackUris.length; i += batchSize) {
      final end = (i + batchSize < trackUris.length) ? i + batchSize : trackUris.length;
      final batch = trackUris.sublist(i, end);

      try {
        await _spotifyApiClient.post(
          '/playlists/$playlistId/tracks',
          body: {'uris': batch},
        );
        print('✅ Added batch ${i ~/ batchSize + 1}/${(trackUris.length / batchSize).ceil()} (${batch.length} tracks)');
      } catch (e) {
        print('❌ Failed to add batch: $e');
        print('📝 Batch URIs: $batch');
        rethrow;
      }
    }
  }

  Future<void> _removeTracksFromPlaylist(String playlistId, List<String> trackIds) async {
    if (trackIds.isEmpty) return;

    // Convert track IDs to Spotify URIs
    final trackUris = trackIds.map((id) {
      if (id.startsWith('spotify:track:')) {
        return id;
      }
      return 'spotify:track:$id';
    }).toList();

    // Remove tracks in batches of 100 (Spotify API limit)
    const batchSize = 100;
    for (int i = 0; i < trackUris.length; i += batchSize) {
      final end = (i + batchSize < trackUris.length) ? i + batchSize : trackUris.length;
      final batch = trackUris.sublist(i, end);

      final tracksToRemove = batch.map((uri) => {'uri': uri}).toList();

      await _spotifyApiClient.delete(
        '/playlists/$playlistId/tracks',
        body: {'tracks': tracksToRemove},
      );
    }
  }

  Future<bool> isPlaylistAccessible(String playlistId) async {
    try {
      await _spotifyApiClient.get('/playlists/$playlistId');
      return true;
    } catch (e) {
      return false;
    }
  }
}
