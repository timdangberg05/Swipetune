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
