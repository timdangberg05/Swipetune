import 'dart:io';
import 'package:swipetune/auth/pkce_generator.dart';
import 'package:swipetune/auth/token_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../auth/deep_link_handler.dart';

class AuthServices {

  //_authService = AuthServices(clientId: 'deb60e6c420e48b789b7a205a25df95e', redirectUri: 'swipetune://callback', scopes: ['user-read-email','playlist-modify','playlist-modify-private','user-top-read']);

  static final String clientId = 'deb60e6c420e48b789b7a205a25df95e';
  static final String redirectUri = 'swipetune://callback';
  static final List<String> scopes = ['user-read-email','playlist-modify','playlist-modify-private','user-top-read'];
  
  static final PkceGenerator _pkce_gen = PkceGenerator();
  static final TokenStore _tokenStore = TokenStore();
  
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

  static Future<void> login() async
  {
    final _dpl = DeepLinkHandler();

    try
    {
      openAuthorizeUrl();
      final code = await _dpl.waitForAuthorizationCode();

      await exchangeAuthCodes(code);
    }
    finally
    {
      _dpl.dispose();
    }
  }

}
