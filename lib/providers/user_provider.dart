import 'package:flutter/material.dart';
import 'package:swipetune/services/user_service.dart';
import '../models/user_model.dart';
import '../API/SpotifyApiClient.dart';

class UserProvider with ChangeNotifier
{
  final UserService _userService;
  
  SpotifyUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserProvider(this._userService);
  
  SpotifyUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadUserProfile() async
  {
    if(_user != null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try
    {
      _user = await _userService.getCurrentUser();
      _isLoading = false;
      notifyListeners();
    }
    catch(e)
    {
      _errorMessage = 'Fehler beim Laden: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearUser()
  {
    _user = null;
    notifyListeners();
  }
}
