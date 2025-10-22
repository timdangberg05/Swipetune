import 'package:swipetune/models/firebasemodels/discover_config.dart';

enum DiscoveryStrategy
{
    coldStart,
    warmUp,
    personalized,
}

class StrategySelector 
{
  static DiscoveryStrategy select(int swipeCount)
  {
    if(swipeCount < DiscoveryConfig.coldStartThreshold)
    {
      return DiscoveryStrategy.coldStart;
    }
    else if(swipeCount < DiscoveryConfig.personalizedThreshold)
    {
      return DiscoveryStrategy.warmUp;
    }
    else {
      return DiscoveryStrategy.personalized;
    }
  }
}