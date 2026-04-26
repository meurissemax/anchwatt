import 'package:shared_preferences/shared_preferences.dart';

class PrefsStorage {
  /* Variables */

  SharedPreferences? prefs;

  /* Methods */

  Future<void> init() async {
    if (prefs != null) {
      return;
    }

    prefs = await SharedPreferences.getInstance();
  }

  int readInt({
    required String key,
    int fallback = 0,
  }) {
    return prefs?.getInt(key) ?? fallback;
  }

  Future<void> writeInt({
    required String key,
    required int value,
  }) async {
    await prefs?.setInt(key, value);
  }

  String? readString({
    required String key,
    String? fallback,
  }) {
    return prefs?.getString(key) ?? fallback;
  }

  Future<void> writeString({
    required String key,
    required String value,
  }) async {
    await prefs?.setString(key, value);
  }

  Future<void> delete({
    required String key,
  }) async {
    await prefs?.remove(key);
  }

  Future<void> deleteAll() async {
    await prefs?.clear();
  }
}
