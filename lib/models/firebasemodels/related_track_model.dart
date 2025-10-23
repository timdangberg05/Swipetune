class RelatedTrack 
{
  final String id;
  final double score;

  RelatedTrack({
    required this.id,
    required this.score,
  });

  factory RelatedTrack.fromMap(Map<String, dynamic> map) 
  {
    return RelatedTrack(
      id: map['id'] as String,
      score: (map['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() 
  {
    return {
      'id': id,
      'score': score,
    };
  }

  @override
  String toString() => 'RelatedTrack(id: $id, score: $score)';
}
