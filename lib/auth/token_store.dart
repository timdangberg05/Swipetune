import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;  

class TokenStore {
  
  final _storage = FlutterSecureStorage();

  static const String _keyAccessToken = 'spotify_access_token';
  static const String _keyRefreshToken = 'spotify_refresh_token';
  static const String _keyExpiresAt = 'spotify_expires_at';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<void> saveExpiresAt(DateTime expiresAt) async {
    await _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String());
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _keyAccessToken);
    return token;
  }

  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: _keyRefreshToken);
    return token;
  }

  Future<DateTime?> getExpiresAt() async {
    final expiresAt = await _storage.read(key: _keyExpiresAt);
    
    if (expiresAt != null) {
      final parsed = DateTime.parse(expiresAt);
      return parsed;
    }
    return null;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresAt);
  }

  Future<bool> isTokenValid() async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) {
      return false;
    }
    
    final isValid = DateTime.now().isBefore(expiresAt);
    return isValid;
  }

  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final isValid = await isTokenValid();
    final hasTokens = accessToken != null && isValid;
    return hasTokens;
  }
}
