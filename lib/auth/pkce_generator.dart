import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PkceGenerator {

  String generateCodeVerifier()
  {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (index) => random.nextInt(256));
    String encoded = base64Url.encode(bytes).replaceAll('=', '');
    
    return encoded;

  }

  String generateCodeChallenge(String verifier)
  {
    var bytes = utf8.encode(verifier);
    var digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

// TODO: Vor Commit entfernen!
void main() {
  print('=== PKCE Generator Test ===\n');
  
  final pkce = PkceGenerator();
  
  // Test Verifier
  final verifier = pkce.generateCodeVerifier();
  print('Code Verifier: $verifier');
  print('Length: ${verifier.length}');
  print('Has padding: ${verifier.contains('=')}');
  
  // Test Challenge
  final challenge = pkce.generateCodeChallenge(verifier);
  print('\nCode Challenge: $challenge');
  print('Length: ${challenge.length}');
  print('Has padding: ${challenge.contains('=')}');
  
  // Test: Gleicher Verifier = Gleicher Challenge
  final challenge2 = pkce.generateCodeChallenge(verifier);
  print('\nDeterministisch (gleicher Challenge): ${challenge == challenge2}');
  
  // Test: Neuer Verifier = Anderer Verifier
  final verifier2 = pkce.generateCodeVerifier();
  print('Verschiedene Verifier: ${verifier != verifier2}');
}