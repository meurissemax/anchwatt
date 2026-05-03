import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/prefs_storage.dart';

class SoundStorage {
  /* Static variables */

  static const String _keyMode = 'sound.mode';

  /* Variables */

  final PrefsStorage _prefsStorage = PrefsStorage();

  /* Methods */

  Future<void> init() => _prefsStorage.init();

  SoundMode readMode() {
    final String? raw = _prefsStorage.readString(key: _keyMode);

    return SoundMode.fromName(raw);
  }

  Future<void> writeMode(SoundMode mode) => _prefsStorage.writeString(
    key: _keyMode,
    value: mode.name,
  );
}
