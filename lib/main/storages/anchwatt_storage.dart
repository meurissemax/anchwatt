import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/prefs_storage.dart';

class AnchwattStorage {
  /* Static variables */

  static const int _schemaVersion = 1;
  static const String _keySchemaVersion = 'anchwatt.schema_version';
  static const String _keyLevel = 'anchwatt.level';
  static const String _keyXp = 'anchwatt.xp';

  /* Variables */

  final PrefsStorage _prefsStorage = PrefsStorage();

  /* Methods */

  Future<void> init() => _prefsStorage.init();

  ({int level, int xp}) readProgression() {
    final int storedVersion = _prefsStorage.readInt(
      key: _keySchemaVersion,
      fallback: -1,
    );

    if (storedVersion != _schemaVersion) {
      return _defaults();
    }

    final int level = _prefsStorage.readInt(
      key: _keyLevel,
      fallback: AnchwattSettings.levelMin,
    );
    final int xp = _prefsStorage.readInt(key: _keyXp);

    if (level < AnchwattSettings.levelMin || level > AnchwattSettings.levelMax) {
      return _defaults();
    }

    // Below the cap, reaching xpForLevel(level) immediately triggers a level-up,
    // so a persisted xp must be strictly under it. At the cap there is no next
    // palier: xp sits exactly at xpForLevel(level) (a full bar), which is valid
    // and must round-trip instead of resetting the character to level 1.
    final int xpCeiling = level >= AnchwattSettings.levelMax
        ? AnchwattSettings.xpForLevel(level)
        : AnchwattSettings.xpForLevel(level) - 1;

    if (xp < 0 || xp > xpCeiling) {
      return _defaults();
    }

    return (level: level, xp: xp);
  }

  Future<void> writeProgression({
    required int level,
    required int xp,
  }) async {
    await _prefsStorage.writeInt(
      key: _keySchemaVersion,
      value: _schemaVersion,
    );
    await _prefsStorage.writeInt(
      key: _keyLevel,
      value: level,
    );
    await _prefsStorage.writeInt(
      key: _keyXp,
      value: xp,
    );
  }

  Future<void> clear() async {
    await _prefsStorage.delete(key: _keySchemaVersion);
    await _prefsStorage.delete(key: _keyLevel);
    await _prefsStorage.delete(key: _keyXp);
  }

  ({int level, int xp}) _defaults() => (level: AnchwattSettings.levelMin, xp: 0);
}
