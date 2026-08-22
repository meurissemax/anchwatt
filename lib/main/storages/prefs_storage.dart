import 'package:shared_preferences/shared_preferences.dart';

class PrefsStorage {
  /* Variables */

  SharedPreferences? _prefs;

  /* Methods */

  Future<void> init() async {
    if (_prefs != null) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();
  }

  bool readBool({
    required String key,
    bool fallback = false,
  }) {
    return _prefs?.getBool(key) ?? fallback;
  }

  Future<void> writeBool({
    required String key,
    required bool value,
  }) async {
    await _prefs?.setBool(key, value);
  }

  int readInt({
    required String key,
    int fallback = 0,
  }) {
    return _prefs?.getInt(key) ?? fallback;
  }

  Future<void> writeInt({
    required String key,
    required int value,
  }) async {
    await _prefs?.setInt(key, value);
  }

  String? readString({
    required String key,
    String? fallback,
  }) {
    return _prefs?.getString(key) ?? fallback;
  }

  Future<void> writeString({
    required String key,
    required String value,
  }) async {
    await _prefs?.setString(key, value);
  }

  Future<void> delete({
    required String key,
  }) async {
    await _prefs?.remove(key);
  }
}
