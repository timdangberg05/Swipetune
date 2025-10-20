import 'package:http/http.dart';
import 'package:swipetune/API/SpotifyApiClient.dart';
import 'package:swipetune/models/Track.dart';
import 'package:swipetune/models/playlist_model.dart';

class PlaylistService {

  final SpotifyApiClient _spotifyApiClient;

  PlaylistService(this._spotifyApiClient);

  Future<List<PlaylistModel>> getUserPlaylists() async {
  print('=== PLAYLIST SERVICE: getUserPlaylists ===');
  
    try {
      // API Call
      final response = await _spotifyApiClient.get('/me/playlists?limit=50');
      
      print('Response received: ${response['total']} total playlists');
      
      // Parse playlists
      final List<PlaylistModel> playlists = [];
      
      if (response['items'] != null) {
        final items = response['items'] as List;
        
        for (var item in items) {
          try {
            final playlist = PlaylistModel.fromMap(item);
            playlists.add(playlist);
            print('✓ Parsed: ${playlist.name} (${playlist.trackCount} tracks)');
          } catch (e) {
            print('⚠️ Failed to parse playlist: $e');
          }
        }
      }
      
      print('Success: Retrieved ${playlists.length} playlists');
      print('==========================================');
      
      return playlists;
      
    } catch (e) {
      print('❌ ERROR in getUserPlaylists: $e');
      print('==========================================');
      return [];
    }
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async 
  {
    print('=== PLAYLIST SERVICE: getPlaylistTracks ===');
    print('Playlist ID: $playlistId');
    
    try {
      // API Call
      final response = await _spotifyApiClient.get('/playlists/$playlistId/tracks?limit=100');
      
      print('Response received: ${response['total']} total tracks');
      
      // Parse tracks
      final List<Track> tracks = [];
      
      if (response['items'] != null) {
        final items = response['items'] as List;
        
        for (var item in items) {
          try {
            // WICHTIG: Track ist in item['track']!
            final trackData = item['track'];
            
            // Check ob Track nicht null (gelöschte Songs)
            if (trackData != null) {
              final track = Track.fromMap(trackData);
              tracks.add(track);
              print('✓ Parsed: ${track.name} - ${track.artist}');
            } else {
              print('⚠️ Skipped null track (deleted/unavailable)');
            }
          } catch (e) {
            print('⚠️ Failed to parse track: $e');
          }
        }
      }
      
      print('Success: Retrieved ${tracks.length} tracks');
      print('============================================');
      
      return tracks;
      
    } catch (e) {
      print('❌ ERROR in getPlaylistTracks: $e');
      print('============================================');
      return [];
    }
  }

  Future<PlaylistModel> createPlaylist(String userId, String name,{String? description,bool isPublic = false}) async
  {
    print('=== PLAYLIST SERVICE: createPlaylist ===');
    print('User ID: $userId');
    print('Name: $name');
    print('Public: $isPublic');

    try
    {
      final Map<String, dynamic> body =
      {
        'name': name,
        'public': isPublic,
      };
      if(description != null && description.isNotEmpty)
      {
        body['description'] = description;

      }
      final response = await _spotifyApiClient.post('/users/$userId/playlists');
      final playlist = PlaylistModel.fromMap(response);
      print('✓ Success: Created playlist "${playlist.name}"');
      print('Playlist ID: ${playlist.id}');
      print('=========================================');
      
      return playlist;
    }
    catch(e)
    {
      print('❌ ERROR in createPlaylist: $e');
      print('=========================================');
      rethrow;
    }
  }

  Future<void> addTracksToPlaylist(String playlistId, List<String> trackUris) async
  {
    try
    {
      final validUris = trackUris.map((uri)
      {
        if(uri.startsWith('spotify:track'))
        {
          return uri;
        }
        return 'spotify:track:$uri';
      }).toList();
      final batches = <List<String>> [];
      for(int i = 0; i < validUris.length; i++)
      {
        final end = (i +100 <validUris.length) ? i + 100 : validUris.length;
        batches.add(validUris.sublist(i, end));
      }

      for(int i = 0; i < batches.length; i++)
      {
        final batch  = batches[i];

        await _spotifyApiClient.post('playlists/$playlistId/tracks', body:{'uris': batch,});
      }
    }
    catch(e)
    {
      print('❌ ERROR in addTracksToPlaylist: $e');
      print('=============================================');
      rethrow;
    }
  }

  Future<void> removeTracksFromPlaylist(String playlistId, List<String> trackUris) async 
  {
    try {
      final validUris = trackUris.map((uri) {
        if (uri.startsWith('spotify:track:')) {
          return uri;
        }
        return 'spotify:track:$uri';
      }).toList();
      final tracks = validUris.map((uri) => {'uri': uri}).toList();
      final batches = <List<Map<String, String>>>[];
      for (int i = 0; i < tracks.length; i += 100) {
        final end = (i + 100 < tracks.length) ? i + 100 : tracks.length;
        batches.add(tracks.sublist(i, end));
      }
      
      print('Processing ${batches.length} batch(es)...');
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        
        print('Removing batch ${i + 1}/${batches.length} (${batch.length} tracks)');
        
        await _spotifyApiClient.delete(
          '/playlists/$playlistId/tracks',
          body: {
            'tracks': batch,
          },
        );
        
        print('✓ Batch ${i + 1} removed successfully');
      }
      
      print('✓ Success: Removed ${trackUris.length} tracks from playlist');
      print('================================================');
      
    } catch (e) {
      print('❌ ERROR in removeTracksFromPlaylist: $e');
      print('================================================');
      rethrow;
    }
  }




  
}