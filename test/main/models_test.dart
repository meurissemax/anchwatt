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
        systemVolume: 1,
      );

      expect(xp, 38);
    });

    test('usbToggle with zero volume awards 0 XP (anti-farming)', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 0,
      );

      expect(xp, 0);
    });

    test('usbToggle scales with system volume between 0 and 1', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 0.5,
      );

      expect(xp, 19);
    });

    test('usbToggle scales with player level', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 50,
        mode: SoundMode.corporate,
        systemVolume: 1,
      );

      expect(xp, 773);
    });

    test('usbToggle clamps systemVolume above 1 to 1', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 1.5,
      );

      expect(xp, 38);
    });

    test('usbToggle clamps negative systemVolume to 0', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
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
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('pet at level 1 with zero volume awards a non-zero floored XP', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 0,
      );

      expect(xp, 1);
    });

    test('pet at level 1 with full volume awards floored base * maxVolumeMultiplier', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 1,
      );

      expect(xp, 5);
    });

    test('pet stays well below usbToggle at full volume', () {
      final int petXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 1,
      );
      final int usbXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
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
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('usbToggle in friday mode awards 1.5x the corporate amount', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.friday,
        systemVolume: 1,
      );

      expect(xp, 56);
    });

    test('usbToggle in friday mode with zero volume still awards 0 XP', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.friday,
        systemVolume: 0,
      );

      expect(xp, 0);
    });

    test('pet in friday mode awards the same XP as in corporate mode', () {
      final int corporateXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 1,
      );
      final int fridayXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.friday,
        systemVolume: 1,
      );

      expect(fridayXp, corporateXp);
    });

    test('usbToggle in hardcore mode awards the highest XP of all modes', () {
      final int corporateXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.corporate,
        systemVolume: 1,
      );
      final int fridayXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.friday,
        systemVolume: 1,
      );
      final int hardcoreXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        mode: SoundMode.hardcore,
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
        systemVolume: 1,
      );
      final int hardcoreXp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.pet,
        level: 1,
        mode: SoundMode.hardcore,
        systemVolume: 1,
      );

      expect(hardcoreXp, corporateXp);
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
