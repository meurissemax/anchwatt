import 'dart:math';

import 'package:anchwatt/main/models.dart';
import 'package:flutter_test/flutter_test.dart';

// A deterministic [Random] whose nextInt always returns [_next] and records the
// bound it was called with, so the shiny odds can be asserted precisely.
class _StubRandom implements Random {
  _StubRandom(this._next);

  final int _next;
  int? lastMax;

  @override
  int nextInt(int max) {
    lastMax = max;

    return _next;
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

AchievementStats _statsWith({
  int totalSystemEvents = 0,
  int petInteractions = 0,
  int shinyEncounters = 0,
  int level = AnchwattSettings.levelMin,
}) => AchievementStats(
  totalSystemEvents: totalSystemEvents,
  petInteractions: petInteractions,
  shinyEncounters: shinyEncounters,
  level: level,
);

void main() {
  group('AnchwattSettings.xpForEvent', () {
    test('usbToggle at level 1 with full volume awards base * maxVolumeMultiplier', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(xp, 38);
    });

    test('usbToggle with zero volume awards 0 XP (anti-farming)', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 0,
      );

      expect(xp, 0);
    });

    test('usbToggle scales with system volume between 0 and 1', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 0.5,
      );

      expect(xp, 19);
    });

    test('usbToggle scales with player level', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 50,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(xp, 773);
    });

    test('usbToggle clamps systemVolume above 1 to 1', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1.5,
      );

      expect(xp, 38);
    });

    test('usbToggle clamps negative systemVolume to 0', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: -0.2,
      );

      expect(xp, 0);
    });

    test('usbToggle without systemVolume triggers assertion', () {
      expect(
        () => AnchwattSettings.xpForEvent(
          type: AnchwattEventType.usbToggle,
          level: 1,
          mode: SoundMode.corporate,
          durationMs: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('pet at level 1 with zero volume awards a non-zero floored XP', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 0,
      );

      expect(xp, 1);
    });

    test('pet at level 1 with full volume awards floored base * maxVolumeMultiplier', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(xp, 5);
    });

    test('pet stays well below usbToggle at full volume', () {
      final int petXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );
      final int usbXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(petXp * 5, lessThanOrEqualTo(usbXp));
    });

    test('pet without systemVolume triggers assertion', () {
      expect(
        () => AnchwattSettings.xpForEvent(
          type: AnchwattEventType.pet,
          level: 1,
          mode: SoundMode.corporate,
          durationMs: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('usbToggle in friday mode awards 1.5x the corporate amount', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.friday,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(xp, 56);
    });

    test('usbToggle in friday mode with zero volume still awards 0 XP', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.friday,
        durationMs: 0,
        systemVolume: 0,
      );

      expect(xp, 0);
    });

    test('pet in friday mode awards the same XP as in corporate mode', () {
      final int corporateXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );
      final int fridayXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.friday,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(fridayXp, corporateXp);
    });

    test('usbToggle in hardcore mode awards the highest XP of all modes', () {
      final int corporateXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );
      final int fridayXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.friday,
        durationMs: 0,
        systemVolume: 1,
      );
      final int hardcoreXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.hardcore,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(hardcoreXp, 75);
      expect(hardcoreXp, greaterThan(fridayXp));
      expect(fridayXp, greaterThan(corporateXp));
    });

    test('pet in hardcore mode awards the same XP as in corporate mode', () {
      final int corporateXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );
      final int hardcoreXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.hardcore,
        durationMs: 0,
        systemVolume: 1,
      );

      expect(hardcoreXp, corporateXp);
    });
  });

  group('AnchwattSettings.durationMultiplier', () {
    test('returns 1.0 for zero and negative durations', () {
      expect(AnchwattSettings.durationMultiplier(0), 1.0);
      expect(AnchwattSettings.durationMultiplier(-100), 1.0);
    });

    test('returns 1.0 up to and including the short bound', () {
      expect(AnchwattSettings.durationMultiplier(1), 1.0);
      expect(AnchwattSettings.durationMultiplier(1499), 1.0);
      expect(AnchwattSettings.durationMultiplier(1500), 1.0);
    });

    test('returns 1.25 from just above the short bound up to the medium bound', () {
      expect(AnchwattSettings.durationMultiplier(1501), 1.25);
      expect(AnchwattSettings.durationMultiplier(2999), 1.25);
      expect(AnchwattSettings.durationMultiplier(3000), 1.25);
    });

    test('returns 1.5 above the medium bound, including huge values', () {
      expect(AnchwattSettings.durationMultiplier(3001), 1.5);
      expect(AnchwattSettings.durationMultiplier(999999999), 1.5);
    });
  });

  group('AnchwattSettings.xpForEvent duration multiplier', () {
    test('a medium sound awards 1.25x with a single final rounding', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 2000,
        systemVolume: 1,
      );

      // 25 * 1.5 (volume) * 1.25 (duration) = 46.875 → 47. An intermediate
      // rounding (38 * 1.25 = 47.5 → 48) would fail this assertion.
      expect(xp, 47);
    });

    test('a long sound awards 1.5x the base amount', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 5000,
        systemVolume: 1,
      );

      expect(xp, 56);
    });

    test('the duration multiplier composes with the mode multiplier', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.friday,
        durationMs: 5000,
        systemVolume: 1,
      );

      // 25 * 1.5 (volume) * 1.5 (mode) * 1.5 (duration) = 84.375 → 84.
      expect(xp, 84);
    });

    test('durationMs 0 matches a short sound (x1, non-regression)', () {
      final int zeroDurationXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 0,
        systemVolume: 1,
      );
      final int shortSoundXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 1500,
        systemVolume: 1,
      );

      expect(zeroDurationXp, 38);
      expect(shortSoundXp, 38);
    });

    test('zero volume still awards 0 XP whatever the duration', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        durationMs: 5000,
        systemVolume: 0,
      );

      expect(xp, 0);
    });
  });

  group('AnchwattSettings.rollShiny', () {
    test('returns true when the RNG hits 0', () {
      expect(AnchwattSettings.rollShiny(_StubRandom(0)), isTrue);
    });

    test('returns false for any non-zero roll', () {
      expect(AnchwattSettings.rollShiny(_StubRandom(1)), isFalse);
      expect(AnchwattSettings.rollShiny(_StubRandom(AnchwattSettings.shinyOdds - 1)), isFalse);
    });

    test('draws from the [0, shinyOdds) range', () {
      final _StubRandom random = _StubRandom(0);
      AnchwattSettings.rollShiny(random);

      expect(random.lastMax, AnchwattSettings.shinyOdds);
    });
  });

  group('AnchwattSettings.isShinyActive', () {
    final DateTime expiresAt = DateTime(2026, 8, 22, 12);

    test('is inactive when no window exists', () {
      expect(AnchwattSettings.isShinyActive(expiresAt: null, now: expiresAt), isFalse);
    });

    test('is active strictly before expiry', () {
      expect(
        AnchwattSettings.isShinyActive(
          expiresAt: expiresAt,
          now: expiresAt.subtract(const Duration(microseconds: 1)),
        ),
        isTrue,
      );
      expect(
        AnchwattSettings.isShinyActive(
          expiresAt: expiresAt,
          now: expiresAt.subtract(AnchwattSettings.shinyDuration),
        ),
        isTrue,
      );
    });

    test('is expired at the expiry instant itself', () {
      expect(AnchwattSettings.isShinyActive(expiresAt: expiresAt, now: expiresAt), isFalse);
    });

    test('is expired after expiry', () {
      expect(
        AnchwattSettings.isShinyActive(
          expiresAt: expiresAt,
          now: expiresAt.add(const Duration(microseconds: 1)),
        ),
        isFalse,
      );
      expect(
        AnchwattSettings.isShinyActive(
          expiresAt: expiresAt,
          now: expiresAt.add(const Duration(hours: 8)),
        ),
        isFalse,
      );
    });
  });

  group('AnchwattSettings.pickTaglineIndex', () {
    test('returns the RNG draw verbatim', () {
      expect(AnchwattSettings.pickTaglineIndex(_StubRandom(0)), 0);
      expect(AnchwattSettings.pickTaglineIndex(_StubRandom(2)), 2);
    });

    test('draws from the [0, statsCardTaglineCount) range', () {
      final _StubRandom random = _StubRandom(0);
      AnchwattSettings.pickTaglineIndex(random);

      expect(random.lastMax, AnchwattSettings.statsCardTaglineCount);
    });
  });

  group('SoundMode', () {
    test('xpMultiplier ranks Hardcore highest', () {
      expect(SoundMode.hardcore.xpMultiplier, AnchwattSettings.hardcoreXpMultiplier);
      expect(SoundMode.hardcore.xpMultiplier, greaterThan(SoundMode.friday.xpMultiplier));
      expect(SoundMode.friday.xpMultiplier, greaterThan(SoundMode.corporate.xpMultiplier));
    });

    test('next cycles Corporate then Friday then Hardcore then back to Corporate', () {
      expect(SoundMode.corporate.next, SoundMode.friday);
      expect(SoundMode.friday.next, SoundMode.hardcore);
      expect(SoundMode.hardcore.next, SoundMode.corporate);
    });

    test('fromName resolves known names and falls back to Corporate otherwise', () {
      expect(SoundMode.fromName('hardcore'), SoundMode.hardcore);
      expect(SoundMode.fromName('nope'), SoundMode.corporate);
      expect(SoundMode.fromName(null), SoundMode.corporate);
    });
  });

  group('Achievement.isUnlockedBy', () {
    test('firstSpark unlocks on the first system event', () {
      expect(Achievement.firstSpark.isUnlockedBy(_statsWith()), isFalse);
      expect(Achievement.firstSpark.isUnlockedBy(_statsWith(totalSystemEvents: 1)), isTrue);
    });

    test('workhorse unlocks at the total-events threshold', () {
      expect(
        Achievement.workhorse.isUnlockedBy(
          _statsWith(totalSystemEvents: AnchwattSettings.achievementTotalEventsThreshold - 1),
        ),
        isFalse,
      );
      expect(
        Achievement.workhorse.isUnlockedBy(
          _statsWith(totalSystemEvents: AnchwattSettings.achievementTotalEventsThreshold),
        ),
        isTrue,
      );
    });

    test('compulsivePetter unlocks at the pets threshold', () {
      expect(
        Achievement.compulsivePetter.isUnlockedBy(
          _statsWith(petInteractions: AnchwattSettings.achievementPetsThreshold - 1),
        ),
        isFalse,
      );
      expect(
        Achievement.compulsivePetter.isUnlockedBy(
          _statsWith(petInteractions: AnchwattSettings.achievementPetsThreshold),
        ),
        isTrue,
      );
    });

    test('chromatic unlocks on the first shiny encounter', () {
      expect(Achievement.chromatic.isUnlockedBy(_statsWith()), isFalse);
      expect(Achievement.chromatic.isUnlockedBy(_statsWith(shinyEncounters: 1)), isTrue);
    });

    test('welcomeToHell unlocks at the Hardcore unlock level', () {
      expect(
        Achievement.welcomeToHell.isUnlockedBy(_statsWith(level: AnchwattSettings.hardcoreUnlockLevel - 1)),
        isFalse,
      );
      expect(
        Achievement.welcomeToHell.isUnlockedBy(_statsWith(level: AnchwattSettings.hardcoreUnlockLevel)),
        isTrue,
      );
    });

    test('endOfLine unlocks at max level', () {
      expect(
        Achievement.endOfLine.isUnlockedBy(_statsWith(level: AnchwattSettings.levelMax - 1)),
        isFalse,
      );
      expect(
        Achievement.endOfLine.isUnlockedBy(_statsWith(level: AnchwattSettings.levelMax)),
        isTrue,
      );
    });

    test('event-count badges ignore pet interactions', () {
      final AchievementStats petsOnly = _statsWith(petInteractions: 5000);

      expect(Achievement.firstSpark.isUnlockedBy(petsOnly), isFalse);
      expect(Achievement.workhorse.isUnlockedBy(petsOnly), isFalse);
    });
  });
}
