import 'firebase_track_model.dart';

class ScoredTrack implements Comparable<ScoredTrack> 
{
  final FirebaseTrack track;
  final double score;

  ScoredTrack({
    required this.track,
    required this.score,
  });

  @override
  int compareTo(ScoredTrack other) 
  {
    return other.score.compareTo(score);
  }

  @override
  String toString() {
    return 'ScoredTrack(track: ${track.name}, artist: ${track.artist}, score: ${score.toStringAsFixed(3)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoredTrack && other.track.id == track.id;
  }

  @override
  int get hashCode => track.id.hashCode;
}
