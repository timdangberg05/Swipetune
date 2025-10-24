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
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Bad Request';
          throw Exception('Spotify API Error (400): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (400): Bad Request - $endpoint');
        }
      case 401:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Invalid Token';
          throw Exception('Spotify API Error (401): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (401): Invalid Token - $endpoint');
        }
      case 403:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Forbidden';
          throw Exception('Spotify API Error (403): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (403): Forbidden - $endpoint');
        }
      case 404:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Resource not found';
          throw Exception('Spotify API Error (404): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (404): Resource not found - $endpoint');
        }
      case >= 500:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Server Error';
          throw Exception('Spotify API Error (${response.statusCode}): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (${response.statusCode}): Server Error - $endpoint');
        }
      default:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Unknown Error';
          throw Exception('Spotify API Error (${response.statusCode}): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (${response.statusCode}): Unknown Error - $endpoint');
        }
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
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Bad Request';
          throw Exception('Spotify API Error (400): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (400): Bad Request - $endpoint');
        }
      case 401:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Invalid Token';
          throw Exception('Spotify API Error (401): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (401): Invalid Token - $endpoint');
        }
      case 403:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Forbidden';
          throw Exception('Spotify API Error (403): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (403): Forbidden - $endpoint');
        }
      case 404:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Resource not found';
          throw Exception('Spotify API Error (404): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (404): Resource not found - $endpoint');
        }
      case >= 500:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Server Error';
          throw Exception('Spotify API Error (${response.statusCode}): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (${response.statusCode}): Server Error - $endpoint');
        }
      default:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Unknown Error';
          throw Exception('Spotify API Error (${response.statusCode}): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (${response.statusCode}): Unknown Error - $endpoint');
        }
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
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Bad Request';
          throw Exception('Spotify API Error (400): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (400): Bad Request - $endpoint');
        }
      case 401:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Invalid Token';
          throw Exception('Spotify API Error (401): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (401): Invalid Token - $endpoint');
        }
      case 403:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Forbidden';
          throw Exception('Spotify API Error (403): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (403): Forbidden - $endpoint');
        }
      case 404:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Resource not found';
          throw Exception('Spotify API Error (404): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (404): Resource not found - $endpoint');
        }
      case >= 500:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Server Error';
          throw Exception('Spotify API Error (${response.statusCode}): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (${response.statusCode}): Server Error - $endpoint');
        }
      default:
        try {
          final errorBody = jsonDecode(response.body);
          final message = errorBody['error']?['message'] ?? 'Unknown Error';
          throw Exception('Spotify API Error (${response.statusCode}): $message - $endpoint');
        } catch (e) {
          throw Exception('Spotify API Error (${response.statusCode}): Unknown Error - $endpoint');
        }
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
      try {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['error']?['message'] ?? 'Search failed';
        throw Exception('Spotify API Error (${response.statusCode}): $message - /v1/search');
      } catch (e) {
        throw Exception('Spotify API Error (${response.statusCode}): Search failed - /v1/search');
      }
    }

  }

}
