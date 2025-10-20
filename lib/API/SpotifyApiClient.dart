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
        switch(response.statusCode) {
      case 200:
        return jsonDecode(response.body);
      case 400:
        throw Exception('Falsche Syntax');
      case 401:
        throw Exception('Invalid Token');
      case 403:
        throw Exception('Forbidden');
      case 404:
        throw Exception('Existiert nicht');
      case >= 500:  
        throw Exception('Server Error (>= 500)');
      default:
        throw Exception('Unbekannter Fehler: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint,{Map<String, dynamic>? body}) async 
  {
    final accessToken = await AuthServices.getValidAccessToken();
    final url = Uri.parse(_baseUrl + endpoint);
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',  
      },
      body: body != null ? jsonEncode(body) : null,
    );
    switch(response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw Exception('Falsche Syntax');
      case 401:
        throw Exception('Invalid Token');
      case 403:
        throw Exception('Forbidden');
      case 404:
        throw Exception('Existiert nicht');
      case >= 500:
        throw Exception('Server Error (>= 500)');
      default:
        throw Exception('Unbekannter Fehler: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint,{Map<String, dynamic>? body}) async 
  {
    final accessToken = await AuthServices.getValidAccessToken();
    
    final url = Uri.parse(_baseUrl + endpoint);
    
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );
    
    switch(response.statusCode) {
      case 200:
      case 204:  
        if (response.body.isEmpty) {
          return {};
        }
        return jsonDecode(response.body);
      case 400:
        throw Exception('Falsche Syntax');
      case 401:
        throw Exception('Invalid Token');
      case 403:
        throw Exception('Forbidden');
      case 404:
        throw Exception('Existiert nicht');
      case >= 500:
        throw Exception('Server Error (>= 500)');
      default:
        throw Exception('Unbekannter Fehler: ${response.statusCode}');
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