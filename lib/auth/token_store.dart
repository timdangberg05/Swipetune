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
