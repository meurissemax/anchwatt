import 'dart:async';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/stats_storage.dart';

// Self-contained gamification counters, shared across the app via get_it and
// incremented from several places (the orchestrating ViewModel and the sound
// service). It tracks its own [lifetimeXp] by accumulating each granted amount,
// so it never reads the XP system's internal representation. Counters are held
// in memory and persisted on every increment (volume is low and already
// debounced upstream, so no batching is needed).
class StatsService {
  /* Variables */

  final StatsStorage _storage = StatsStorage();

  DateTime? _firstLaunch;
  final Map<AnchwattEventType, int> _eventCounts = <AnchwattEventType, int>{};
  int _petInteractions = 0;
  int _soundsPlayed = 0;
  final Map<SoundMode, int> _soundsByMode = <SoundMode, int>{};
  int _lifetimeXp = 0;
  int _shinyEncounters = 0;
  int _totalSoundDurationMs = 0;

  /* Getters */

  DateTime? get firstLaunchDate => _firstLaunch;
  int get petInteractions => _petInteractions;
  int get soundsPlayed => _soundsPlayed;
  int get lifetimeXp => _lifetimeXp;
  int get shinyEncounters => _shinyEncounters;
  int get totalSoundDurationMs => _totalSoundDurationMs;

  int get totalSystemEvents {
    int total = 0;

    for (final MapEntry<AnchwattEventType, int> entry in _eventCounts.entries) {
      if (entry.key == AnchwattEventType.pet) {
        continue;
      }

      total += entry.value;
    }

    return total;
  }

  int eventCount(AnchwattEventType type) => _eventCounts[type] ?? 0;

  int soundsPlayedFor(SoundMode mode) => _soundsByMode[mode] ?? 0;

  /* Methods */

  Future<void> init() async {
    await _storage.init();

    _firstLaunch = _storage.readFirstLaunch();
    _eventCounts
      ..clear()
      ..addAll(_storage.readEventCounts());
    _petInteractions = _storage.readPetInteractions();
    _soundsPlayed = _storage.readSoundsPlayed();
    _soundsByMode
      ..clear()
      ..addAll(_storage.readSoundsByMode());
    _lifetimeXp = _storage.readLifetimeXp();
    _shinyEncounters = _storage.readShinyCount();
    _totalSoundDurationMs = _storage.readTotalSoundDurationMs();

    // Seed the "member since" date once, on the first run where it is absent.
    if (_firstLaunch == null) {
      final DateTime now = DateTime.now();
      _firstLaunch = now;
      await _storage.writeFirstLaunch(now);
    }
  }

  void recordSystemEvent(AnchwattEventType type) {
    _eventCounts[type] = (_eventCounts[type] ?? 0) + 1;
    unawaited(_storage.writeEventCounts(_eventCounts));
  }

  void recordPetInteraction() {
    _petInteractions += 1;
    unawaited(_storage.writePetInteractions(_petInteractions));
  }

  void recordSoundPlayed(SoundMode mode) {
    _soundsPlayed += 1;
    _soundsByMode[mode] = (_soundsByMode[mode] ?? 0) + 1;
    unawaited(_storage.writeSoundsPlayed(_soundsPlayed));
    unawaited(_storage.writeSoundsByMode(_soundsByMode));
  }

  void addLifetimeXp(int amount) {
    if (amount <= 0) {
      return;
    }

    _lifetimeXp += amount;
    unawaited(_storage.writeLifetimeXp(_lifetimeXp));
  }

  // Accumulates the nominal duration of a sound that was actually played
  // (DND / empty-pool paths never reach this). Cries are excluded upstream,
  // consistent with [recordSoundPlayed].
  void recordSoundDuration(int durationMs) {
    if (durationMs <= 0) {
      return;
    }

    _totalSoundDurationMs += durationMs;
    unawaited(_storage.writeTotalSoundDurationMs(_totalSoundDurationMs));
  }

  void recordShinyEncounter() {
    _shinyEncounters += 1;
    unawaited(_storage.writeShinyCount(_shinyEncounters));
  }

  Future<void> reset() async {
    final DateTime now = DateTime.now();

    _eventCounts.clear();
    _petInteractions = 0;
    _soundsPlayed = 0;
    _soundsByMode.clear();
    _lifetimeXp = 0;
    _shinyEncounters = 0;
    _totalSoundDurationMs = 0;
    _firstLaunch = now;

    await _storage.clear();
    await _storage.writeFirstLaunch(now);
  }
}
