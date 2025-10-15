 import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {


  final _storage = FlutterSecureStorage();

  static const String _keyAccessToken = 'spotify_access_token';
  static const String _keyRefreshToken = 'spotify_refresh_token';
  static const String _keyExpiresAt = 'Spotify_expires_at';


  Future<void> saveAccessToken(String token) async {
     await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<void> saveExpiresAt(DateTime expiresAt) async
  {
    await _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String());
  }

  Future<String?> getAccessToken( ) async 
  {
    final keyAccessToken =  await _storage.read(key: _keyAccessToken);
    if(keyAccessToken != null)
    {
      return keyAccessToken;
    }
    return null;
  }

  Future<String?> getRefreshToken( ) async 
  {
    final keyRefreshToken =  await _storage.read(key: _keyRefreshToken);
    if(keyRefreshToken != null)
    {
      return keyRefreshToken;
    }
    return null;
  }

  Future<DateTime?> getExpiresAt() async 
  {
    final expiresAt = await _storage.read(key: _keyExpiresAt);
    if(expiresAt != null)
    {
      return DateTime.parse(expiresAt);
    }
    return null;

  }
  Future<void> clearTokens( ) async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresAt);
  }

  Future<bool>isTokenValid() async
  {
    final expiresAt = await getExpiresAt();
    if(expiresAt == null) return false;
    final isvalid = DateTime.now().isBefore(expiresAt);
    return isvalid;

  }

  Future<bool> hasValidTokens() async
  {
    final accessToken = await getAccessToken();
    final isvalid = await isTokenValid();
    return accessToken != null && isvalid;
  }  
 }
