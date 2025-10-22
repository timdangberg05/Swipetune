import 'package:swipetune/models/firebasemodels/discover_config.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';
import 'package:swipetune/models/firebasemodels/user_preferences_model.dart';

class ThresholdFilter 
{
  static bool isTrackBlocked(String trackId, UserPreference uprefs)
  {
    final count = uprefs.trackDislikeCounts[trackId] ?? 0;
    return count >= DiscoveryConfig.trackDislikeThreshold;
  }

  static bool isArtistBlocked(String artistId, UserPreference uprefs)
  {
    final count = uprefs.artistDislikeCounts[artistId] ?? 0;
    return count >= DiscoveryConfig.artistDislikeThreshold;
  }

  static bool isGenreSoftBlocked(String genreId, UserPreference uprefs)
  {
    final count = uprefs.genreDislikeCounts[genreId] ?? 0;
    return count >= DiscoveryConfig.genreSoftBlockThreshold;
  }

  static bool shouldSkipTrack(FirebaseTrack _fbt, UserPreference uprefs)
  {
    if(isTrackBlocked(_fbt.id, uprefs)) return true;
    if(isArtistBlocked(_fbt.primaryArtistId, uprefs)) return true;
    if(_fbt.collectedGenres.isNotEmpty)
    {
      final allGenreIsBlocked = _fbt.collectedGenres.every((genre)=> isGenreSoftBlocked(genre, uprefs));
      if(allGenreIsBlocked) return true;
    }
    return false;
  }
}