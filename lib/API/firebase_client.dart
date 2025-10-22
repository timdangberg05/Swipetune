import 'dart:math';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swipetune/models/firebasemodels/firebase_track_model.dart';
import 'package:swipetune/models/firebasemodels/track_artist_model.dart';
import 'package:swipetune/models/firebasemodels/user_preferences_model.dart';


class FirebaseClient 
{
  final FirebaseFirestore _firestore;
  final Random _random = Random();
  
  FirebaseClient({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;
  
  Future<List<FirebaseTrack>> getTracks({int limit = 50,String? orderBy,bool descending = false,String? genreFilter,int? minPopularity}) async 
  {
    Query<Map<String, dynamic>> query = _firestore.collection('tracks');
    if (genreFilter != null) 
    {
      query = query.where('collected_genres', arrayContains: genreFilter);
    }

    if (minPopularity != null) 
    {
      query = query.where('popularity', isGreaterThanOrEqualTo: minPopularity);
    }
    if (orderBy != null) 
    {
      query = query.orderBy(orderBy, descending: descending);
    }
    query = query.limit(limit);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => FirebaseTrack.fromMap(doc.data()))
        .toList();
  }

  Future<FirebaseTrack?> getTrackById(String trackId) async
  {
    final doc = await _firestore.collection('tracks').doc(trackId).get();
    if(!doc.exists) return null;
    return FirebaseTrack.fromMap(doc.data()!);
  }

  Future<List<FirebaseTrack>> getTracksByArtist(String artistId, {int limit = 5}) async 
  {
    final snapshot = await _firestore
        .collection('tracks')
        .where('primaryArtistId', isEqualTo: artistId)
        .orderBy('popularity', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => FirebaseTrack.fromMap(doc.data())).toList();
  }
  /// Lädt Genre Weights aus Firestore metadata/genre_weights
/// Struktur: { "weights": { "acid jazz": { "nu jazz": 0.313, ... }, ... } }
  Future<Map<String, dynamic>?> getGenreWeights() async 
  {
    try {
      final doc = await _firestore
          .collection('metadata')
          .doc('genre_weights')
          .get();
      
      if (!doc.exists) {
        print('⚠️ Genre weights document not found');
        return null;
      }
      
      final data = doc.data();
      if (data == null) return null;
      
      return data['weights'] as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Error loading genre weights: $e');
      return null;
    }
  }
List<String> extractTop5RelatedGenres(String genre, Map<String, dynamic> allWeights) 
{
  final genreWeights = allWeights[genre] as Map<String, dynamic>?;
  
  if (genreWeights == null) {
    print('⚠️ No weights found for genre: "$genre"');
    return [];
  }

  final filtered = Map<String, dynamic>.from(genreWeights);
  filtered.remove(genre);

  final sorted = filtered.entries.toList()
    ..sort((a, b) => (b.value as num).compareTo(a.value as num));
  final top5 = sorted.take(5).map((e) => e.key as String).toList();
  
  return top5;
}

Future<List<FirebaseTrack>> getTracksByGenres({required List<String> genres,int limit = 20,String? orderBy,bool descending = false}) async 
{
  if (genres.isEmpty) return [];
  final limitedGenres = genres.take(10).toList();
  Query<Map<String, dynamic>> query = _firestore
      .collection('tracks')
      .where('collected_genres', arrayContainsAny: limitedGenres);
  if (orderBy != null) {
    query = query.orderBy(orderBy, descending: descending);
  }
  query = query.limit(limit);
  final snapshot = await query.get();
  return snapshot.docs
      .map((doc) => FirebaseTrack.fromMap(doc.data()))
      .toList();
}
}
