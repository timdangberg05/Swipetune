import '../API/LRClibApiClient.dart';
import '../models/Track.dart';

class LyricsService {
  final LRClibApiClient _apiClient;

  LyricsService(this._apiClient);

  Future<String?> getLyrics(Track track) async {
    final title = _cleanTitle(track.name);
    final artist = track.artist;
    final duration = (track.durationMs / 1000).round();

    final lyrics = await _fetchWithDuration(title, artist, duration);
    if (lyrics != null) return lyrics;

    return await _fetchWithoutDuration(title, artist);
  }

  Future<String?> _fetchWithDuration(
    String title,
    String artist,
    int duration,
  ) async {
    final response = await _apiClient.get('/get', {
      'track_name': title,
      'artist_name': artist,
      'duration': duration.toString(),
    });

    return response?['plainLyrics'];
  }

  Future<String?> _fetchWithoutDuration(
    String title,
    String artist,
  ) async {
    final response = await _apiClient.get('/get', {
      'track_name': title,
      'artist_name': artist,
    });

    return response?['plainLyrics'];
  }

  String _cleanTitle(String name) {
    String clean = name;
    clean = clean.replaceAll(
      RegExp(r'\(feat\..*?\)', caseSensitive: false),
      '',
    );
    clean = clean.replaceAll(
      RegExp(r'\[feat\..*?\]', caseSensitive: false),
      '',
    );
    return clean.trim();
  }
}
