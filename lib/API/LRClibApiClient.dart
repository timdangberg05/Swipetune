import 'package:http/http.dart' as http;
import 'dart:convert';

class LRClibApiClient {
  final String _baseUrl = 'https://lrclib.net/api';

  Future<Map<String, dynamic>?> get(
    String endpoint,
    Map<String, String> queryParams,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
