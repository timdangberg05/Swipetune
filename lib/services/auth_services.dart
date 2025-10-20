import 'dart:io';
import 'package:flutter/material.dart';
import 'package:swipetune/auth/pkce_generator.dart';
import 'package:swipetune/auth/token_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../auth/deep_link_handler.dart';

class AuthServices {

  static final String clientId = 'deb60e6c420e48b789b7a205a25df95e';
  static final String redirectUri = 'swipetune://callback';
  static final List<String> scopes = ['user-read-email','user-read-private','playlist-modify-public','playlist-modify-private','user-top-read','playlist-read-private'];
  
  static final PkceGenerator _pkce_gen = PkceGenerator();
  static final TokenStore _tokenStore = TokenStore();

  static TokenStore get tokenStore => _tokenStore;
  
  static String? _codeVerifier;

  AuthServices._();

  static void openAuthorizeUrl()
  {
    _codeVerifier = _pkce_gen.generateCodeVerifier();
    var codechallenge = _pkce_gen.generateCodeChallenge(_codeVerifier!);
    final scropeString = scopes.join(' ');
    final uri = Uri.https(
      'accounts.spotify.com',
      '/authorize',
      {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': scropeString,
        'code_challenge_method': 'S256',
        'code_challenge': codechallenge,
      }
    );
    /* return uri.toString(); */
    _launchURL(uri);
  }

  static _launchURL(Uri uri) async{
    if(!await launchUrl(uri)){
      throw Exception("URL konnte nicht gestartet werden"); 
    }
  }


  static Future<void> exchangeAuthCodes(String code) async
  {
    final body = 
    {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': _codeVerifier!,
    };
    final response = await http.post
    (
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    switch(response.statusCode)
    {
      case 200:
        final data = json.decode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final expiresIn = data['expires_in'] as int;

        final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));


        await _tokenStore.saveAccessToken(accessToken);
        await _tokenStore.saveRefreshToken(refreshToken);
        await _tokenStore.saveExpiresAt(expiresAt);

        print('Login erfolgreich');
        break;

      case 400:
        print('Ungültiger Request');
        break;
      case 401:
        print('Unautorisierter reqeust');
      break;
      default: 
        print('unbekannter Fehler');
      break;
    }
  }

  static Future<void> refreshAccessToken() async
  {
    final refreshToken = await _tokenStore.getRefreshToken();
    if(refreshToken == null)
    {
        throw Exception("Kein RefreshToken -- User muss sich neu einloggen");
    }
    final response = await http.post
    (
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: 
      {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
      },
    );

    switch(response.statusCode)
    {
      case 200:
        final data = json.decode(response.body);
        final accessToken = data['access_token'];
        final newrefreshToken = data['refresh_token'];
        final expiresIn = data['expires_in'] as int;

        final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));


        await _tokenStore.saveAccessToken(accessToken);
        await _tokenStore.saveExpiresAt(expiresAt);
        if (newrefreshToken != null) 
        {
        await _tokenStore.saveRefreshToken(newrefreshToken);
        }


        print('token korrekt refreshed');
        break;

      case 400:
        print('Ungültiger Request');
        throw Exception('Token Refresh fehlgeschlagen: Bad Request');
      case 401:
        print('FreshToken ungültig');
        throw Exception('Token Refresh fehlgeschlagen: Unauthorized');
      default: 
        print('unbekannter Fehler');
        throw Exception('Token Refresh fehlgeschlagen: ${response.statusCode}');
    }
  }

  static Future<String> getValidAccessToken() async
  {
    final isValid = await _tokenStore.isTokenValid();
    if(!isValid)
    {
      await refreshAccessToken();
    }
    final token = await _tokenStore.getAccessToken();

    if(token == null)
    {
      throw Exception('Kein Access Token vorhanden');
    }

    return token;
  }

  static Future<void> login() async
  {
    final _dpl = DeepLinkHandler();

    try
    {
      openAuthorizeUrl();
      final code = await _dpl.waitForAuthorizationCode();

      await exchangeAuthCodes(code);
    }
    catch (e) 
    {
    print('❌ [AuthService] Login fehlgeschlagen: $e\n');
    rethrow; 
    }
    finally
    {
      _dpl.dispose();
    }
  }

  static Future<void> logout() async
  {
    _tokenStore.clearTokens();
  }
}



