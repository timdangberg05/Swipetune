import 'package:swipetune/models/firebasemodels/discover_config.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';
import 'package:swipetune/models/firebasemodels/user_preferences_model.dart';

class TrackScoring
{

  static double calculate(FirebaseTrack track, UserPreference uprefs)
  {
    double score = 1.0;
    score += _calculateTrackPenalty(track.id, uprefs);
    score += _calculateArtistPenalty(track.primaryArtistId, uprefs);
    score += _calculateGenrePenalty(track.collectedGenres, uprefs);
    score += _calculateArtistBonus(track.primaryArtistId, uprefs);
    score += _calculateGenreBonus(track.collectedGenres, uprefs);
    score += _calculatePopularityBonus(track.popularity);
    score += _calculateRecencyPenalty(track.id, uprefs);
    score += _calculateRelatedTrackBonus(track, uprefs);
    return score;
  }
  static double _calculateTrackPenalty(String trackId, UserPreference uprefs) 
  {
    final count = uprefs.trackDislikeCounts[trackId] ?? 0;
    if (count >= DiscoveryConfig.trackDislikeThreshold) 
    {
      return -999.0;
    }
    return count * DiscoveryConfig.trackPenaltyMultiplier;
  }

  static double _calculateArtistPenalty(String artistId, UserPreference uprefs)
  {
    final count = uprefs.artistDislikeCounts[artistId] ?? 0;
    if(count >= DiscoveryConfig.artistDislikeThreshold)
    {
      return -999.0;
    }
    return count * DiscoveryConfig.artistPenaltyMultiplier;
  }

  static double _calculateGenrePenalty(List<String> genres, UserPreference uprefs)
  {
    double totalGenrePenalty = 0.0;
    for(final genre in genres)
    {
      final count = uprefs.genreDislikeCounts[genre] ?? 0;
      if(count >= DiscoveryConfig.genreSoftBlockThreshold)
      {
        totalGenrePenalty += DiscoveryConfig.genreSoftBlockPenalty;
      }
      else
      {
        totalGenrePenalty += count * DiscoveryConfig.genrePenaltyMultiplier;
      }
    }
    return totalGenrePenalty;
  }

  static double _calculateArtistBonus(String artistId, UserPreference uprefs)
  {
    final  likeCount = uprefs.artistLikeCounts[artistId] ?? 0;
    final bonus =  likeCount * DiscoveryConfig.artistLikeMultiplier;
    return bonus.clamp(0.0, DiscoveryConfig.maxArtistBonus);
  }

  static double _calculateGenreBonus(List<String> genres, UserPreference uprefs)
  {
    double totalBonus = 0.0;
    for(final genre in genres)
    {
      final likeCount = uprefs.genreLikeCounts[genre] ?? 0;
      totalBonus += likeCount * DiscoveryConfig.genreLikeMultiplier;  
    }
    return totalBonus.clamp(0.0, DiscoveryConfig.maxGenreBonus);  
  }

  static double _calculateRelatedTrackBonus(FirebaseTrack track, UserPreference uprefs)
  {
    double bonus = 0.0;
    for(final likedTrackId in uprefs.likedTracks)
    {
      for(final related in track.relatedTracks)
      {
        if(related.id == likedTrackId && related.score >= DiscoveryConfig.similarityThreshold)
        {
          bonus += DiscoveryConfig.relatedTrackBonus;
        }
      }
    }
    return bonus;
  }
  static double _calculatePopularityBonus(int popularity)
  {
    final normalized = (popularity - DiscoveryConfig.popularityMidpoint);
    return normalized * DiscoveryConfig.popularityMultiplier;
  }

  static double _calculateRecencyPenalty(String trackId, UserPreference uprefs)
  {
    final recentSwipes = uprefs.swipeHistory.take(DiscoveryConfig.recencyWindowSize).toList();
    if(recentSwipes.contains(trackId))
    {
      return DiscoveryConfig.recencyPenalty;
    }
    return 0.0;
  }
}