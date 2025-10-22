class UserPreference 
{
  final Set<String> likedTracks;
  final Set<String> dislikedTracks;
  final List<String> swipeHistory;
  final Map<String, int> trackDislikeCounts;
  final Map<String, int> trackLikeCounts;
  final Map<String, int> artistDislikeCounts;
  final Map<String, int> artistLikeCounts;
  final Map<String, int> genreDislikeCounts;
  final Map<String, int> genreLikeCounts;
  final Set<String> likedArtists;
  final Set<String> likedGenres;
  final Set<String> dislikedArtists;
  final Set<String> dislikedGenres;
  final DateTime? lastSwipeTime;
  final Map<String, List<String>> expandedGenres;

  
  int get totalSwipes => swipeHistory.length;

  UserPreference({
    required this.likedTracks,
    required this.dislikedTracks,
    required this.swipeHistory,
    required this.trackDislikeCounts,
    required this.trackLikeCounts,
    required this.artistDislikeCounts,
    required this.artistLikeCounts,
    required this.genreDislikeCounts,
    required this.genreLikeCounts,
    required this.likedArtists,
    required this.likedGenres,
    required this.dislikedArtists,
    required this.dislikedGenres,
    this.lastSwipeTime,
    required this.expandedGenres,
  });

  factory UserPreference.empty() 
  {
    return UserPreference(
      likedTracks: {},
      dislikedTracks: {},
      swipeHistory: [],
      trackDislikeCounts: {},
      trackLikeCounts: {},
      artistDislikeCounts: {},
      artistLikeCounts: {},
      genreDislikeCounts: {},
      genreLikeCounts: {},
      likedArtists: {},
      likedGenres: {},
      dislikedArtists: {},
      dislikedGenres: {},
      expandedGenres: {},
    );
  }

  factory UserPreference.fromMap(Map<dynamic, dynamic> map) 
  {
    return UserPreference(
      likedTracks: (map['liked_tracks'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      dislikedTracks: (map['disliked_tracks'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      swipeHistory: (map['swipe_history'] as List<dynamic>?)?.cast<String>() ?? [],
      trackDislikeCounts: _convertToIntMap(map['track_dislike_counts']),
      trackLikeCounts: _convertToIntMap(map['track_like_counts']),
      artistDislikeCounts: _convertToIntMap(map['artist_dislike_counts']),
      artistLikeCounts: _convertToIntMap(map['artist_like_counts']),
      genreDislikeCounts: _convertToIntMap(map['genre_dislike_counts']),
      genreLikeCounts: _convertToIntMap(map['genre_like_counts']),
      expandedGenres: _convertToExpandedGenresMap(map['expanded_genres']),
      likedArtists: (map['liked_artists'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      likedGenres: (map['liked_genres'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      dislikedArtists: (map['dislikedArtists'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      dislikedGenres: (map['dislikedGenres'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      lastSwipeTime: _parseDateTime(map['last_swipe_time']),
    );
  }

static DateTime? _parseDateTime(dynamic value) 
{
  if (value == null) return null;
  
  try {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return null;
  } catch (e) {
    print('⚠️ Error parsing DateTime: $e');
    return null;
  }
}

  static Map<String, int> _convertToIntMap(dynamic data) 
  {
    if (data == null) return {};
    
    try {
      final sourceMap = data as Map;
      final result = <String, int>{};
      
      sourceMap.forEach((key, value) {
        result[key.toString()] = (value as num).toInt();
      });
      
      return result;
    } catch (e) {
      print('⚠️ Error in _convertToIntMap: $e');
      return {};
    }
  }
  static Map<String, List<String>> _convertToExpandedGenresMap(dynamic data) 
  {
    if (data == null) return {};
    
    try {
      final sourceMap = data as Map;
      final result = <String, List<String>>{};
      
      sourceMap.forEach((key, value) {
        final stringKey = key.toString();
        final list = (value as List).map((item) => item.toString()).toList();
        result[stringKey] = list;
      });
      
      return result;
    } catch (e) {
      print('⚠️ Error in _convertToExpandedGenresMap: $e');
      return {};
    }
  }


  Map<String, dynamic> toMap() 
  {
    return {
      'liked_tracks': likedTracks.toList(),
      'disliked_tracks': dislikedTracks.toList(),
      'swipe_history': swipeHistory,
      'track_dislike_counts': trackDislikeCounts,
      'track_like_counts': trackLikeCounts,
      'artist_dislike_counts': artistDislikeCounts,
      'artist_like_counts': artistLikeCounts,
      'genre_dislike_counts': genreDislikeCounts,
      'genre_like_counts': genreLikeCounts,
      'liked_artists': likedArtists.toList(),
      'liked_genres': likedGenres.toList(),
      'dislikedArtists': dislikedArtists.toList(),
      'dislikedGenres': dislikedGenres.toList(),
      'last_swipe_time': lastSwipeTime?.toIso8601String(),
      'expanded_genres': expandedGenres,
    };
  }

  UserPreference copyWith({
    Set<String>? likedTracks,
    Set<String>? dislikedTracks,
    List<String>? swipeHistory,
    Map<String, int>? trackDislikeCounts,
    Map<String, int>? trackLikeCounts,
    Map<String, int>? artistDislikeCounts,
    Map<String, int>? artistLikeCounts,
    Map<String, int>? genreDislikeCounts,
    Map<String, int>? genreLikeCounts,
    Set<String>? likedArtists,
    Set<String>? likedGenres,
    Set<String>? dislikedArtists,
    Set<String>? dislikedGenres,
    DateTime? lastSwipeTime,
    Map<String, List<String>>? expandedGenres,
  }) 
  {
    return UserPreference(
      likedTracks: likedTracks ?? this.likedTracks,
      dislikedTracks: dislikedTracks ?? this.dislikedTracks,
      swipeHistory: swipeHistory ?? this.swipeHistory,
      trackDislikeCounts: trackDislikeCounts ?? this.trackDislikeCounts,
      trackLikeCounts: trackLikeCounts ?? this.trackLikeCounts,
      artistDislikeCounts: artistDislikeCounts ?? this.artistDislikeCounts,
      artistLikeCounts: artistLikeCounts ?? this.artistLikeCounts,
      genreDislikeCounts: genreDislikeCounts ?? this.genreDislikeCounts,
      genreLikeCounts: genreLikeCounts ?? this.genreLikeCounts,
      likedArtists: likedArtists ?? this.likedArtists,
      likedGenres: likedGenres ?? this.likedGenres,
      dislikedArtists: dislikedArtists ?? this.dislikedArtists,
      dislikedGenres: dislikedGenres ?? this.dislikedGenres,
      lastSwipeTime: lastSwipeTime ?? this.lastSwipeTime,
      expandedGenres: expandedGenres ?? this.expandedGenres,
    );
  }
}
