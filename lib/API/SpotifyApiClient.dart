import 'package:http/http.dart' as http;
import 'package:swipetune/services/auth_services.dart';
import '../auth/token_store.dart';
import 'dart:convert';


class SpotifyApiClient{

  final TokenStore _tokenstore = TokenStore();
  static final String _baseUrl = 'https://api.spotify.com/v1';

  Future<Map<String, dynamic>> get(String endpoint) async{

    if(!await _tokenstore.isTokenValid()){
      AuthServices.refreshAccessToken();
    }
    final accessToken = _tokenstore.getAccessToken();

    final url = Uri.parse(_baseUrl + endpoint);

    
    final response = await http.get(
    url,
    headers: {
      'Authorization' : 'Bearer $accessToken'
    },
    
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if(response.statusCode == 401){
      throw Exception('Invalid Token');
    } else if(response.statusCode == 403){
      throw Exception('kein PLan');
    } else{
      throw Exception('kein PLan');
    }

  }
}