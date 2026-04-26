import 'package:anchwatt/main/storages/prefs_storage.dart';

class UpdateStorage {
  /* Static variables */

  static const String _keyLastCheckAt = 'update.last_check_at';
  static const String _keyLatestVersionSeen = 'update.latest_version_seen';
  static const String _keyLatestReleaseUrl = 'update.latest_release_url';

  /* Variables */

  final PrefsStorage _prefsStorage = PrefsStorage();

  /* Methods */

  Future<void> init() => _prefsStorage.init();

  ({int? lastCheckAt, String? latestVersionSeen, String? latestReleaseUrl}) read() {
    final int rawCheck = _prefsStorage.readInt(
      key: _keyLastCheckAt,
      fallback: -1,
    );

    return (
      lastCheckAt: rawCheck < 0 ? null : rawCheck,
      latestVersionSeen: _prefsStorage.readString(key: _keyLatestVersionSeen),
      latestReleaseUrl: _prefsStorage.readString(key: _keyLatestReleaseUrl),
    );
  }

  Future<void> write({
    required int lastCheckAt,
    required String latestVersionSeen,
    required String latestReleaseUrl,
  }) async {
    await _prefsStorage.writeInt(
      key: _keyLastCheckAt,
      value: lastCheckAt,
    );
    await _prefsStorage.writeString(
      key: _keyLatestVersionSeen,
      value: latestVersionSeen,
    );
    await _prefsStorage.writeString(
      key: _keyLatestReleaseUrl,
      value: latestReleaseUrl,
    );
  }

  Future<void> writeTimestamp({
    required int lastCheckAt,
  }) async {
    await _prefsStorage.writeInt(
      key: _keyLastCheckAt,
      value: lastCheckAt,
    );
  }
}
