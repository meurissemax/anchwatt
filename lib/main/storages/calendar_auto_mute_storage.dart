import 'package:anchwatt/main/storages/prefs_storage.dart';

class CalendarAutoMuteStorage {
  /* Static variables */

  static const String _keyEnabled = 'calendar_auto_mute.enabled';

  /* Variables */

  final PrefsStorage _prefsStorage = PrefsStorage();

  /* Methods */

  Future<void> init() => _prefsStorage.init();

  bool readEnabled() => _prefsStorage.readBool(key: _keyEnabled);

  Future<void> writeEnabled(bool value) => _prefsStorage.writeBool(
    key: _keyEnabled,
    value: value,
  );
}
