class DiscoveryConfig 
{
  static const int trackDislikeThreshold = 3;
  static const int artistDislikeThreshold = 8;
  static const int genreSoftBlockThreshold = 20;
  static const int coldStartBatchSize = 20;
  static const int discoveryBatchSize = 15;
  static const int prefetchPoolSize = 50;
  static const double trackPenaltyMultiplier = -0.35;
  static const double artistPenaltyMultiplier = -0.25;
  static const double genrePenaltyMultiplier = -0.15;
  static const double genreSoftBlockPenalty = -5.0;
  static const double artistLikeMultiplier = 0.15;
  static const double genreLikeMultiplier = 0.10;
  static const double maxArtistBonus = 1.0;
  static const double maxGenreBonus = 0.8;
  static const int coldStartThreshold = 5;
  static const int personalizedThreshold = 20;
  static const double recencyPenalty = -2.0;
  static const int recencyWindowSize = 50;
  static const double popularityMultiplier = 1.0 / 200.0;
  static const int popularityMidpoint = 50;
  static const double relatedTrackBonus = 0.3;
  static const double similarityThreshold = 0.85;
  static const double exploitationRatio = 0.7;
  static const double explorationRatio = 0.2;
  static const double serendipityRatio = 0.1;
}
