import 'dart:convert';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/prefs_storage.dart';
import 'package:flutter/foundation.dart';

class StatsStorage {
  /* Static variables */

  static const String _keyFirstLaunch = 'stats.first_launch';
  static const String _keyEventCounts = 'stats.event_counts';
  static const String _keyPetInteractions = 'stats.pet_interactions';
  static const String _keySoundsPlayed = 'stats.sounds_played';
  static const String _keySoundsByMode = 'stats.sounds_by_mode';
  static const String _keyLifetimeXp = 'stats.lifetime_xp';

  /* Variables */

  final PrefsStorage _prefsStorage = PrefsStorage();

  /* Methods */

  Future<void> init() => _prefsStorage.init();

  DateTime? readFirstLaunch() {
    final int millis = _prefsStorage.readInt(
      key: _keyFirstLaunch,
      fallback: -1,
    );

    if (millis <= 0) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> writeFirstLaunch(DateTime date) => _prefsStorage.writeInt(
    key: _keyFirstLaunch,
    value: date.millisecondsSinceEpoch,
  );

  Map<AnchwattEventType, int> readEventCounts() => _decodeCountMap<AnchwattEventType>(
    _prefsStorage.readString(key: _keyEventCounts),
    AnchwattEventType.values,
  );

  Future<void> writeEventCounts(Map<AnchwattEventType, int> counts) => _prefsStorage.writeString(
    key: _keyEventCounts,
    value: _encodeCountMap(counts),
  );

  int readPetInteractions() => _prefsStorage.readInt(key: _keyPetInteractions);

  Future<void> writePetInteractions(int value) => _prefsStorage.writeInt(
    key: _keyPetInteractions,
    value: value,
  );

  int readSoundsPlayed() => _prefsStorage.readInt(key: _keySoundsPlayed);

  Future<void> writeSoundsPlayed(int value) => _prefsStorage.writeInt(
    key: _keySoundsPlayed,
    value: value,
  );

  Map<SoundMode, int> readSoundsByMode() => _decodeCountMap<SoundMode>(
    _prefsStorage.readString(key: _keySoundsByMode),
    SoundMode.values,
  );

  Future<void> writeSoundsByMode(Map<SoundMode, int> counts) => _prefsStorage.writeString(
    key: _keySoundsByMode,
    value: _encodeCountMap(counts),
  );

  int readLifetimeXp() => _prefsStorage.readInt(key: _keyLifetimeXp);

  Future<void> writeLifetimeXp(int value) => _prefsStorage.writeInt(
    key: _keyLifetimeXp,
    value: value,
  );

  Future<void> clear() async {
    await _prefsStorage.delete(key: _keyFirstLaunch);
    await _prefsStorage.delete(key: _keyEventCounts);
    await _prefsStorage.delete(key: _keyPetInteractions);
    await _prefsStorage.delete(key: _keySoundsPlayed);
    await _prefsStorage.delete(key: _keySoundsByMode);
    await _prefsStorage.delete(key: _keyLifetimeXp);
  }

  // Enum-keyed maps are persisted as a JSON object keyed by [Enum.name] (never
  // the index) so reordering an enum later cannot corrupt the data. Reads are
  // defensive: a malformed payload, an unknown key or a non-int value all
  // resolve to a missing entry, which the service reads back as 0.
  Map<T, int> _decodeCountMap<T extends Enum>(String? raw, List<T> values) {
    final Map<T, int> result = <T, int>{};

    if (raw == null || raw.isEmpty) {
      return result;
    }

    try {
      final Object? decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return result;
      }

      for (final T value in values) {
        final Object? count = decoded[value.name];

        if (count is num) {
          result[value] = count.toInt();
        }
      }
    } on Object catch (error) {
      debugPrint('StatsStorage: failed to decode count map: $error');

      return <T, int>{};
    }

    return result;
  }

  String _encodeCountMap<T extends Enum>(Map<T, int> counts) => jsonEncode(<String, int>{
    for (final MapEntry<T, int> entry in counts.entries) entry.key.name: entry.value,
  });
}
