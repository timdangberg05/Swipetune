import 'dart:io';

import 'package:flutter_application_2/auth/pkce_generator.dart';
import 'package:flutter_application_2/auth/token_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthServices {

  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  
  final PkceGenerator _pkce_gen = PkceGenerator();
  final TokenStore _tokenStore = TokenStore();
  
  String? _codeVerifier;

  AuthServices({
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
  });

  String getAuthorizeUrl()
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
      return uri.toString();
    }

    Future<void> exchangeAuthCodes(String code) async
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

          await _tokenStore.saveAccessToken(accessToken);
          await _tokenStore.saveRefreshToken(refreshToken);

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

}
void main() async {
  print('╔════════════════════════════════════════╗');
  print('║   Spotify OAuth PKCE Login Flow       ║');
  print('╚════════════════════════════════════════╝\n');
  
  final auth = AuthServices(
    clientId: 'deb60e6c420e48b789b7a205a25df95e',  
    redirectUri: 'http://127.0.0.1:8080/callback',
    scopes: [
      'user-read-email',
      'playlist-modify-public',
      'playlist-modify-private',
      'user-top-read',
    ],
  );
  

  print('📋 Schritt 1: Authorize-URL generieren...\n');
  final url = auth.getAuthorizeUrl();
  
  print('✅ URL generiert!\n');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Öffne diese URL im Browser:');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print(url);
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  print('📝 Anleitung:');
  print('1. Öffne die URL oben im Browser');
  print('2. Logge dich bei Spotify ein');
  print('3. Bestätige die Berechtigungen');
  print('4. Kopiere den "code" Parameter aus der Redirect-URL\n');
  
  print('Beispiel Redirect-URL:');
  print('http://127.0.0.1:8080/callback?code=AQBgUh...\n');
  print('                                     ^^^^^^^^ Das brauchst du!\n');
  

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  stdout.write('Füge den Code hier ein: ');
  final code = stdin.readLineSync()?.trim();
  
  if (code == null || code.isEmpty) {
    print('❌ Kein Code eingegeben. Programm beendet.');
    return;
  }
  

  print('\n🔄 Schritt 2: Code gegen Token tauschen...\n');
  
  try {
    await auth.exchangeAuthCodes(code);
    

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Login erfolgreich!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    final accessToken = await auth._tokenStore.getAccessToken();
    final refreshToken = await auth._tokenStore.getRefreshToken();
    
    print('📦 Gespeicherte Tokens:');
    print('   Access Token:  ${accessToken?.substring(0, 30)}...');
    print('   Refresh Token: ${refreshToken?.substring(0, 30)}...\n');
    
    print('🎉 OAuth Flow erfolgreich abgeschlossen!');
    print('💾 Tokens sind im TokenStore gespeichert.');
    
  } catch (e) {
    print('\n❌ Fehler beim Token-Exchange:');
    print('   $e\n');
    print('💡 Mögliche Ursachen:');
    print('   - Code ist abgelaufen (max. 10 Minuten gültig)');
    print('   - Code wurde bereits verwendet');
    print('   - Client ID stimmt nicht überein');
    print('   - Redirect URI stimmt nicht überein\n');
    print('🔄 Starte das Programm neu und versuche es erneut.');
  }
}



