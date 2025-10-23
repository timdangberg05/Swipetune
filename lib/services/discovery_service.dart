import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:swipetune/API/SpotifyApiClient.dart';
import 'package:swipetune/API/firebase_client.dart';
import 'package:swipetune/models/firebasemodels/discover_config.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';
import 'package:swipetune/models/firebasemodels/user_preferences_model.dart';
import 'package:swipetune/utils/local_preferences_storage.dart';
import 'package:swipetune/utils/scoring_logic.dart';
import 'package:swipetune/utils/strategy_selector.dart';
import 'package:swipetune/utils/threshold_filter.dart';

class DiscoveryService 
{
  final FirebaseClient _firebaseClient;
  final SpotifyApiClient _spotifyApiClient;
  final LocalPreferenceStorage _localPreferenceStorage;
  final Set<String> _recentlyShownIds = {};
  final int _maxHistorySize = 100; 
  Map<String, dynamic>? _cachedGenreWeights;


  DiscoveryService(this._firebaseClient,this._localPreferenceStorage,this._spotifyApiClient);

  Future<UserPreference> _getOrCreatePreference() async 
  {
    // Füge das irgendwo temporär ein:
    try {
      final prefs = await _localPreferenceStorage.getUserPreference();
      if (prefs.totalSwipes == 0 && 
          prefs.likedTracks.isEmpty && 
          prefs.dislikedTracks.isEmpty &&
          prefs.likedGenres.isEmpty
        ) 
      {
        final emptyPrefs = UserPreference.empty();
        await _localPreferenceStorage.updateUserPreference(emptyPrefs);
        return emptyPrefs;
      }
      return prefs;
    } catch (e) {
      print('Error loading preferences: $e');
      await Hive.deleteBoxFromDisk('user_preferences');
      final storage = LocalPreferenceStorage();
      await storage.init();
      return UserPreference.empty();
    }
  }
  Future<String?> getDeezerPreviewUrl(FirebaseTrack track) async
  {
    final trackname = track.name;
    final artist = track.primaryArtistName;
    final baseUrl = 'api.deezer.com';
    final endpoint = '/search';
    final queryParameters = {'q': 'artist:"$artist" track:"$trackname"'};

    final url = Uri.https(baseUrl, endpoint, queryParameters);
    print(url);

    final response = await http.get(url);

    if(response.statusCode == 200){
      Map<String, dynamic> map = jsonDecode(response.body);
      
      return map['data'][0]['preview'];
      
    } else {
      throw Exception('Error occured');
    }

  }
  Future<List<String>> getTopGenresFromSpotify() async 
  {
  try {
    final response = await _spotifyApiClient.get('/me/top/artists?limit=20&time_range=medium_term');
    
    final Set<String> genres = {};
    final artists = response['items'] as List?;
    
    if (artists != null) {
      for (final artist in artists) {
        final artistGenres = artist['genres'] as List?;
        if (artistGenres != null) {
          for (final genre in artistGenres) {
            genres.add(genre.toString().toLowerCase());
          }
        }
      }
    }
    return genres.toList();
  } catch (e) {
    print('❌ Error fetching top genres: $e');
    return [];
  }
}
Future<void> initializeWithSpotifyGenres() async 
{
  try {
    final uprefs = await _getOrCreatePreference();
    if (uprefs.likedGenres.isEmpty && uprefs.totalSwipes == 0) {
      final spotifyGenres = await getTopGenresFromSpotify();
      
      if (spotifyGenres.isEmpty) return;
      
      final updatedPrefs = uprefs.copyWith(
        likedGenres: spotifyGenres.toSet(),
      );
      
      await _localPreferenceStorage.updateUserPreference(updatedPrefs);
      print('✅ Initialized with ${spotifyGenres.length} Spotify genres');
    }
  } catch (e) {
    print('❌ Error initializing Spotify genres: $e');
  }
}
  Future<List<FirebaseTrack>> fetchTracks(DiscoveryStrategy strategy, UserPreference uprefs) async 
  {
    return await fetchTrackBasedOnStrategy(
      strategy, 
      uprefs, 
      _recentlyShownIds  
    );
  }
  Future<List<FirebaseTrack>> fetchTrackBasedOnStrategy(DiscoveryStrategy strategy, UserPreference uprefs,Set<String> recentlyShownTrackIds) async 
  {
    switch(strategy) 
    {
      case DiscoveryStrategy.coldStart:
        final Set<String> addedIds = {};
        final List<FirebaseTrack> coldStartPool = [];
        await initializeWithSpotifyGenres();
        await Future.delayed(Duration(milliseconds: 500));
        final prefswithGenres = await _getOrCreatePreference();
        print('🔍 DEBUG: likedGenres count = ${prefswithGenres.likedGenres.length}');
        print('🔍 DEBUG: likedGenres = ${prefswithGenres.likedGenres}');
        if (prefswithGenres.likedGenres.isNotEmpty) {
          print('🌟 Cold Start with ${prefswithGenres.likedGenres.length} onboarding genres');
          await _ensureGenresExpanded(prefswithGenres.likedGenres);
          final updatedPrefs = await _getOrCreatePreference();
          final expandedGenreList = _collectExpandedGenres(
            prefswithGenres.likedGenres,
            updatedPrefs.expandedGenres
          );
          final genreTracks = await _firebaseClient.getTracksByGenres(
            genres: expandedGenreList,
            limit: 20,
            orderBy: 'popularity',
            descending: true,
          );
          print('🔥 Firebase returned ${genreTracks.length} tracks for genres');
          print('🔥 Requested genres: $expandedGenreList');
          if (genreTracks.isNotEmpty) {
            print('🔥 Sample track genres: ${genreTracks.first}');
          }
          
          for (final track in genreTracks) {
            if (!addedIds.contains(track.id) && !recentlyShownTrackIds.contains(track.id)) {
              coldStartPool.add(track);
              addedIds.add(track.id);
            }
          }
        }
        if (coldStartPool.length < 20) {
          final random = Random();
          final strategies = [() => _firebaseClient.getTracks(limit: 10,orderBy: 'popularity',descending: true,),
            () => _firebaseClient.getTracks(
              limit: 10,
              orderBy: 'collected_year',
              descending: random.nextBool(),
            ),
            () => _firebaseClient.getTracks(
              limit: 10,
              orderBy: 'name',
              descending: false,
            ),
          ];
          strategies.shuffle();
          for (final strategy in strategies) {
            if (coldStartPool.length >= 20) break;
            final tracks = await strategy();
            for (final track in tracks) {
              if (!addedIds.contains(track.id) && !recentlyShownTrackIds.contains(track.id)) {
                coldStartPool.add(track);
                addedIds.add(track.id);
                if (coldStartPool.length >= 20) break;
              }
            }
          }
        }
        
        print('✅ Cold Start pool: ${coldStartPool.length} tracks');
        coldStartPool.shuffle();
        return coldStartPool;
      case DiscoveryStrategy.warmUp:
        final Set<String> addedIds = {};
        final List<FirebaseTrack> warmUpPool = [];
        final popularTracks = await _firebaseClient.getTracks(
          limit: 8,
          orderBy: 'popularity',
          descending: true,
        );
        
        for (final track in popularTracks) {
          if (!addedIds.contains(track.id) && !recentlyShownTrackIds.contains(track.id)) {
            warmUpPool.add(track);
            addedIds.add(track.id);
          }
        }
        if (uprefs.likedGenres.isNotEmpty) {
          await _ensureGenresExpanded(uprefs.likedGenres);
          final updatedPrefs = await _getOrCreatePreference();
          final expandedGenreList = _collectExpandedGenres(
            uprefs.likedGenres,
            updatedPrefs.expandedGenres
          ); 
          print('🎵 WarmUp with ${expandedGenreList.length} expanded genres');
          final genreTracks = await _firebaseClient.getTracksByGenres(
            genres: expandedGenreList,
            limit: 15,
            orderBy: 'popularity',
            descending: true,
          );
          for (final track in genreTracks) {
            if (!addedIds.contains(track.id) && !recentlyShownTrackIds.contains(track.id)) {
              warmUpPool.add(track);
              addedIds.add(track.id);
            }
          }
        }
        if (uprefs.likedTracks.isNotEmpty) {
          final shuffledLiked = uprefs.likedTracks.toList()..shuffle();
          final trackToCheck = shuffledLiked.first;
          final track = await _firebaseClient.getTrackById(trackToCheck);
          if (track != null && track.relatedTracks.isNotEmpty) {
            final relatedIds = (track.relatedTracks.toList()..shuffle())
                .take(5)
                .map((r) => r.id);
            for (final trackId in relatedIds) {
              if (!addedIds.contains(trackId) && !recentlyShownTrackIds.contains(trackId)) {
                final relTrack = await _firebaseClient.getTrackById(trackId);
                if (relTrack != null) {
                  warmUpPool.add(relTrack);
                  addedIds.add(trackId);
                }
              }
            }
          }
        }
        
        print('✅ WarmUp pool: ${warmUpPool.length} tracks');
        warmUpPool.shuffle();
        return warmUpPool;
      case DiscoveryStrategy.personalized:
        final Set<String> addedIds = {};
        final List<FirebaseTrack> discoveryPool = [];
        if (uprefs.likedTracks.isNotEmpty) {
          final shuffledLiked = uprefs.likedTracks.toList()..shuffle();
          final tracksToCheck = shuffledLiked.take(3);
          print('🔗 Checking related tracks from ${tracksToCheck.length} liked tracks');
          int relatedTracksAdded = 0;
          for (final likedTrackId in tracksToCheck) 
          {
            final track = await _firebaseClient.getTrackById(likedTrackId);
            if (track != null && track.relatedTracks.isNotEmpty) 
            {
              final relatedIds = (track.relatedTracks.toList()..shuffle())
                  .take(6)
                  .map((r) => r.id);
              for (final trackId in relatedIds) 
              {
                if (!addedIds.contains(trackId) && !recentlyShownTrackIds.contains(trackId)) 
                {
                  final relTrack = await _firebaseClient.getTrackById(trackId);
                  if (relTrack != null) {
                    discoveryPool.add(relTrack);
                    addedIds.add(trackId);
                    relatedTracksAdded++;
                  }
                }
              }
            }
          }
          print('  ✓ Added $relatedTracksAdded from related tracks');
        }
        if (uprefs.likedArtists.isNotEmpty) {
          final artistList = uprefs.likedArtists.toList()..shuffle();
          final artistsToCheck = artistList.take(2);
          print('🎤 Checking ${artistsToCheck.length} liked artists');
          int artistTracksAdded = 0;
          for (final artistId in artistsToCheck) {
            final artistTracks = await _firebaseClient.getTracksByArtist(
              artistId, 
              limit: 5
            );
            
            for (final track in artistTracks) {
              if (!addedIds.contains(track.id) && !recentlyShownTrackIds.contains(track.id)) {
                discoveryPool.add(track);
                addedIds.add(track.id);
                artistTracksAdded++;
              }
            }
          }
          print('  ✓ Added $artistTracksAdded from artists');
        }
        if (uprefs.likedGenres.isNotEmpty) {
          await _ensureGenresExpanded(uprefs.likedGenres);
          final updatedPrefs = await _getOrCreatePreference();
          final expandedGenreList = _collectExpandedGenres(
            uprefs.likedGenres,
            updatedPrefs.expandedGenres
          );
          print('🎵 Genre Discovery with ${expandedGenreList.length} expanded genres');
          final genreTracks = await _firebaseClient.getTracksByGenres(
            genres: expandedGenreList,
            limit: 20,
            orderBy: 'collected_year',
          );
          int genreTracksAdded = 0;
          for (final track in genreTracks) {
            if (!addedIds.contains(track.id) && !recentlyShownTrackIds.contains(track.id)) {
              discoveryPool.add(track);
              addedIds.add(track.id);
              genreTracksAdded++;
            }
          }
          print('  ✓ Added $genreTracksAdded from genres');
        }
        if (discoveryPool.length < 10) {
          print('⚠️ Pool too small (${discoveryPool.length}), adding fallback');
          
          final fallbackTracks = await _firebaseClient.getTracks(
            limit: 20,
            orderBy: 'popularity',
            descending: false,
          );
          
          for (final track in fallbackTracks) {
            if (!addedIds.contains(track.id) && !recentlyShownTrackIds.contains(track.id)) {
              discoveryPool.add(track);
              addedIds.add(track.id);
            }
          }
        }
        print('✅ Personalized pool: ${discoveryPool.length} tracks');
        discoveryPool.shuffle();
        return discoveryPool;
    }
  }
  List<FirebaseTrack> filterTracks(List<FirebaseTrack> tracks,UserPreference uprefs)
  {
    final seenIds = uprefs.swipeHistory.toSet();
    return tracks.where((track) =>!seenIds.contains(track.id) && !ThresholdFilter.shouldSkipTrack(track, uprefs)).toList();
  }

  List<FirebaseTrack> scoreAndSort(List<FirebaseTrack> tracks,UserPreference uprefs)
  {
    final scoredTracks = tracks.map((track)
    {
      final score = TrackScoring.calculate(track,uprefs);
      return (track: track, score: score);
    }
    ).toList();
    scoredTracks.sort((a, b) => b.score.compareTo(a.score));
    return scoredTracks.map((item) => item.track).toList();
  }

  Future<List<FirebaseTrack>> getDiscoveryFeed({int batchSize = 15}) async 
  {
    final uprefs = await _getOrCreatePreference();
    final strategy = StrategySelector.select(uprefs.totalSwipes);
    
    print('🎯 Strategy: $strategy, totalSwipes: ${uprefs.totalSwipes}');
    
    final rawTracks = await fetchTrackBasedOnStrategy(strategy, uprefs,_recentlyShownIds);
    print('📥 Loaded ${rawTracks.length} tracks from Firebase');
    
    final filteredTracks = filterTracks(rawTracks, uprefs);
    print('🔍 After filter: ${filteredTracks.length} tracks');
    print('   Disliked artists: ${uprefs.dislikedArtists.length}');
    print('   Disliked genres: ${uprefs.dislikedGenres.length}');
    
    final scoredTracks = scoreAndSort(filteredTracks, uprefs);
    print('⭐ After scoring: ${scoredTracks.length} tracks');
    
    return scoredTracks.take(batchSize).toList();
  }

  Future<Map<String, dynamic>?> _loadGenreWeights() async 
  {
    if (_cachedGenreWeights != null) {
      return _cachedGenreWeights;
    }
    
    _cachedGenreWeights = await _firebaseClient.getGenreWeights();
    if (_cachedGenreWeights != null) {
      print('✓ Cached ${_cachedGenreWeights!.keys.length} genre weights');
    }
    return _cachedGenreWeights;
  }

  List<String> _extractTop5RelatedGenres(String genre, Map<String, dynamic> allWeights) 
  {
    final genreWeights = allWeights[genre] as Map<String, dynamic>?;
    if (genreWeights == null) {
      print('⚠️ No weights found for genre: $genre');
      return [];
    }
    final filtered = Map<String, dynamic>.from(genreWeights)..remove(genre);
    final sorted = filtered.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final top5 = sorted.take(5).map((e) => e.key as String).toList();
    
    return top5;
  }

void expandGenreInBackground(String genre) {
  _expandGenre(genre).catchError((e) {
    print('⚠️ Background genre expansion failed for "$genre": $e');
  });
}

Future<void> _expandGenre(String genre) async 
{

  final prefs = await _getOrCreatePreference();
  if (prefs.expandedGenres.containsKey(genre)) {
    print('✓ Genre "$genre" already expanded');
    return;
  }
  final weights = await _loadGenreWeights();
  if (weights == null) return;
  final related = _extractTop5RelatedGenres(genre, weights);
  
  if (related.isEmpty) {
    print('⚠️ No related genres found for "$genre"');
    return;
  }
  
  print('🎯 Expanded "$genre" → $related');
  final updatedExpandedGenres = Map<String, List<String>>.from(prefs.expandedGenres);
  updatedExpandedGenres[genre] = related;
  
  final updatedPrefs = prefs.copyWith(expandedGenres: updatedExpandedGenres);

  await _localPreferenceStorage.updateUserPreference(updatedPrefs);
  print('✓ Saved expanded genres to preferences');
}
Future<void> _ensureGenresExpanded(Set<String> genres) async 
{
  final prefs = await _getOrCreatePreference();
  
  final missingGenres = genres.where((g) => !prefs.expandedGenres.containsKey(g)).toSet();
  
  if (missingGenres.isEmpty) {
    return; 
  }
  
  print('⏳ Lazy expanding ${missingGenres.length} missing genres: $missingGenres');
  final weights = await _loadGenreWeights();
  if (weights == null) return;
  final updatedExpandedGenres = Map<String, List<String>>.from(prefs.expandedGenres);
  
  for (final genre in missingGenres) {
    final related = _extractTop5RelatedGenres(genre, weights);
    if (related.isNotEmpty) {
      updatedExpandedGenres[genre] = related;
      print('  ✓ $genre → $related');
    }
  }
  final updatedPrefs = prefs.copyWith(expandedGenres: updatedExpandedGenres);
  await _localPreferenceStorage.updateUserPreference(updatedPrefs);
}
List<String> _collectExpandedGenres(Set<String> likedGenres, Map<String, List<String>> expandedGenres) 
{
  final Set<String> allGenres = {};
  
  for (final genre in likedGenres) {
    allGenres.add(genre); 
    
    if (expandedGenres.containsKey(genre)) {
      allGenres.addAll(expandedGenres[genre]!); 
    }
  }
  final genreList = allGenres.toList()..shuffle();
  final limited = genreList.take(10).toList();
  
  print('🎵 Genre pool: ${allGenres.length} total → using ${limited.length} for query');
  print('   Genres: $limited');
  
  return limited;
}







}
