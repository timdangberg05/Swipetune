import 'package:hive_flutter/hive_flutter.dart';
import 'package:swipetune/models/firebasemodels/user_preferences_model.dart';

class LocalPreferenceStorage {
  static const String _boxName = 'user_preferences';
  static const String _key = 'current';
  
  Box<dynamic>? _box;
  
  Future<void> init() async {
    await Hive.initFlutter();
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (e) {
      print('⚠️ Box Type Mismatch detected - deleting old box...');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<dynamic>(_boxName);
      print('✅ New box created successfully!');
    }
  }
  
  Future<UserPreference> getUserPreference() async 
  {
  try {
    print('📖 Loading preferences...');
    final data = _box?.get(_key);
    print('📖 Raw data: $data');
    if (data == null) {
      return UserPreference.empty();
    }
    return UserPreference.fromMap(data);
  } catch (e) {
    print('⚠️ Error reading preferences, returning empty: $e');
    return UserPreference.empty();
  }
}

  
  Future<void> updateUserPreference(UserPreference prefs) async 
  {
    print('💾 Saving preferences: likedGenres=${prefs.likedGenres.length}');
    print('💾 Box is null? ${_box == null}');
    await _box?.put(_key, prefs.toMap());
    print('💾 Saved successfully');
  }
  
  Future<void> clearUserPreference() async {
    await _box?.delete(_key);
  }
  
  Future<void> close() async {
    await _box?.close();
  }
}
