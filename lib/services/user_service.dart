import '../API/SpotifyApiClient.dart';
import '../models/user_model.dart';

class UserService
{
  final SpotifyApiClient _apiClient;
  
  UserService(this._apiClient);
  
  Future<SpotifyUser> getCurrentUser() async
{
  final response = await _apiClient.get('/me');
  
  print('=== SPOTIFY USER DEBUG ===');
  print('ID: ${response['id']}');
  print('Display Name: ${response['display_name']}');
  print('Email: ${response['email']}');
  print('Product: ${response['product']}');
  print('Followers: ${response['followers']}');
  print('========================');
  
  return SpotifyUser.fromMap(response);
}
}
