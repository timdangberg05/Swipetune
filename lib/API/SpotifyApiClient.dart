import 'package:http/http.dart' as http;
import 'package:swipetune/services/auth_services.dart';
import '../auth/token_store.dart';
import 'dart:convert';


class SpotifyApiClient{

  static final String _baseUrl = 'https://api.spotify.com/v1';

  Future<Map<String, dynamic>> get(String endpoint) async{

    final accessToken = await AuthServices.getValidAccessToken();

    final url = Uri.parse(_baseUrl + endpoint);

    
    final response = await http.get(
    url,
    headers: {
      'Authorization' : 'Bearer $accessToken'
    },
    
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if(response.statusCode == 400){
        throw Exception('falsche Syntax');      
    } else if(response.statusCode == 401){
        throw Exception('Invalid Token');
    } else if(response.statusCode == 403){
        throw Exception('Forbidden');
    } else if(response.statusCode == 404){
        throw Exception('Existiert nicht');
    } else if(response.statusCode >= 500){
      throw Exception('ueber 500');
    }else{
      throw Exception('kein Plan');
    }

  }

  Future<Map<String, dynamic>> runQuery(String name)async{

    final accessToken = await AuthServices.getValidAccessToken();

    final queryParameters = {
      'q': name,
      'type': 'track',
      'limit': '10',
      'market': 'US',
    };

    final url = Uri.https('api.spotify.com', '/v1/search', queryParameters);

    final response = await http.get(
      url,
      headers: {
        'Authorization' : 'Bearer $accessToken'
      }
    );
    
    if(response.statusCode == 200){
      return jsonDecode(response.body);
    } else{
      throw Exception('Fehler');
    }

  }

}