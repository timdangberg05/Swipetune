 class TokenStore {

  String? _accesstoken;
  String? _refreshToken;


  Future<void> saveAccessToken(String token) async {
    _accesstoken = token;
  }

  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }

  Future<String?> getAccessToken( ) async {
    return _accesstoken;
  }

  Future<String?> getRefreshToken( ) async {
    return _refreshToken;
  }
  Future<void> clearTokens( ) async {
    _accesstoken = null;
    _refreshToken = null;
  }
  
 }

 void main() async {
  final store = TokenStore();
  
  await store.saveAccessToken('test_access_123');
  await store.saveRefreshToken('test_refresh_456');
  
  print('Access Token: ${await store.getAccessToken()}');
  print('Refresh Token: ${await store.getRefreshToken()}');
  
  await store.clearTokens();
  print('Nach Clear - Access: ${await store.getAccessToken()}');
  print('Nach Clear - Refresh: ${await store.getRefreshToken()}');
}