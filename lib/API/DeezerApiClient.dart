

import 'dart:convert';

import 'package:http/http.dart' as http;

class DeezerApiClient{


  Future<Map<String, dynamic>> searchQuery(String trackname, String artist) async{

    final baseUrl = 'api.deezer.com';
    final endpoint = '/search';
    final queryParameters = {'q': 'artist:"${artist}" track:"${trackname}"'};

    final url = Uri.https(baseUrl, endpoint, queryParameters);

    final response = await http.get(url);

    if(response.statusCode == 200){
      return jsonDecode(response.body);
    } else {
      throw Exception('Error occured');
    }

  }
  

}