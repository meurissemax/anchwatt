import 'dart:convert';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/prefs_storage.dart';
import 'package:flutter/foundation.dart';

class AchievementsStorage {
  /* Static variables */

  static const String _keyUnlocked = 'achievements.unlocked';
  static const String _keySeeded = 'achievements.seeded';

  /* Variables */

  final PrefsStorage _prefsStorage = PrefsStorage();

  /* Methods */

  Future<void> init() => _prefsStorage.init();

  Set<Achievement> readUnlocked() => _decodeIdSet(
    _prefsStorage.readString(key: _keyUnlocked),
  );

  Future<void> writeUnlocked(Set<Achievement> unlocked) => _prefsStorage.writeString(
    key: _keyUnlocked,
    value: _encodeIdSet(unlocked),
  );

  bool readSeeded() => _prefsStorage.readBool(key: _keySeeded);

  Future<void> writeSeeded(bool value) => _prefsStorage.writeBool(
    key: _keySeeded,
    value: value,
  );

  Future<void> clear() async {
    await _prefsStorage.delete(key: _keyUnlocked);
    await _prefsStorage.delete(key: _keySeeded);
  }

  // The unlocked set is persisted as a JSON array of [Achievement.name] (never
  // the index) so reordering the enum later cannot corrupt the data. Reads are
  // defensive: a malformed payload or an unknown name resolves to nothing, so a
  // renamed or removed badge simply reads back as locked.
  Set<Achievement> _decodeIdSet(String? raw) {
    final Set<Achievement> result = <Achievement>{};

    if (raw == null || raw.isEmpty) {
      return result;
    }

    try {
      final Object? decoded = jsonDecode(raw);

      if (decoded is! List<dynamic>) {
        return result;
      }

      for (final Object? name in decoded) {
        for (final Achievement achievement in Achievement.values) {
          if (achievement.name == name) {
            result.add(achievement);
          }
        }
      }
    } on Object catch (error) {
      debugPrint('AchievementsStorage: failed to decode unlocked set: $error');

      return <Achievement>{};
    }

    return result;
  }

  String _encodeIdSet(Set<Achievement> unlocked) => jsonEncode(<String>[
    for (final Achievement achievement in unlocked) achievement.name,
  ]);
}
