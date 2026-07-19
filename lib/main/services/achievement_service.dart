import 'dart:async';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/achievements_storage.dart';

// Owns the set of unlocked badges and drives evaluation. Plain and passive like
// [StatsService] (its sibling): it holds no Flutter reactivity and is read from
// / written to directly. The orchestrating ViewModel feeds it a settled
// [AchievementStats] snapshot on every stat change and reacts to the returned
// newly-unlocked list. Registered as a get_it singleton so the stats modal can
// read the unlocked set on demand.
class AchievementService {
  /* Variables */

  final AchievementsStorage _storage = AchievementsStorage();

  final Set<Achievement> _unlocked = <Achievement>{};
  // Guards the retroactive first-run pass: badges already satisfied when the
  // feature first ships are unlocked silently (no notification). Only unlocks
  // that happen after seeding are reported to the caller.
  bool _seeded = false;

  /* Getters */

  bool isUnlocked(Achievement achievement) => _unlocked.contains(achievement);

  /* Methods */

  Future<void> init() async {
    await _storage.init();

    _unlocked
      ..clear()
      ..addAll(_storage.readUnlocked());
    _seeded = _storage.readSeeded();
  }

  // Evaluates every not-yet-unlocked badge against [stats], unlocks the newly
  // satisfied ones and persists the change. Returns the badges that unlocked on
  // this tick so the caller can notify — empty on the first-run seeding pass, so
  // pre-existing progress never triggers a notification burst. Returned in enum
  // order, giving a stable ordering for a combined notification.
  List<Achievement> evaluate(AchievementStats stats) {
    final List<Achievement> newlyUnlocked = <Achievement>[];
    bool changed = false;

    for (final Achievement achievement in Achievement.values) {
      if (_unlocked.contains(achievement) || !achievement.isUnlockedBy(stats)) {
        continue;
      }

      _unlocked.add(achievement);
      changed = true;

      // Report only once the retroactive seeding pass is behind us.
      if (_seeded) {
        newlyUnlocked.add(achievement);
      }
    }

    if (!_seeded) {
      _seeded = true;
      changed = true;
    }

    if (changed) {
      unawaited(_persist());
    }

    return newlyUnlocked;
  }

  Future<void> reset() async {
    _unlocked.clear();
    _seeded = false;

    await _storage.clear();
  }

  Future<void> _persist() async {
    await _storage.writeUnlocked(_unlocked);
    await _storage.writeSeeded(_seeded);
  }
}
