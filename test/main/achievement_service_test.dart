import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/achievement_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('the first run seeds already-satisfied badges silently', () async {
    final AchievementService service = AchievementService();
    await service.init();

    // An existing install with high stats: several badges are already satisfied
    // the very first time the feature evaluates.
    final List<Achievement> reported = service.evaluate(
      _statsWith(
        totalSystemEvents: AnchwattSettings.achievementTotalEventsThreshold,
        level: AnchwattSettings.levelMax,
      ),
    );

    // Seeding reports nothing (no notification burst)...
    expect(reported, isEmpty);
    // ...yet the satisfied badges are unlocked.
    expect(service.isUnlocked(Achievement.firstSpark), isTrue);
    expect(service.isUnlocked(Achievement.workhorse), isTrue);
    expect(service.isUnlocked(Achievement.endOfLine), isTrue);
    expect(service.isUnlocked(Achievement.welcomeToHell), isTrue);
    // Unmet ones stay locked.
    expect(service.isUnlocked(Achievement.chromatic), isFalse);
    expect(service.isUnlocked(Achievement.compulsivePetter), isFalse);
  });

  test('reports a genuinely new unlock once seeding is done, and only once', () async {
    final AchievementService service = AchievementService();
    await service.init();

    // First run seeds against empty stats (nothing satisfied).
    expect(service.evaluate(_statsWith()), isEmpty);
    expect(service.isUnlocked(Achievement.firstSpark), isFalse);

    // Crossing the first-event threshold now reports the badge.
    expect(
      service.evaluate(_statsWith(totalSystemEvents: 1)),
      <Achievement>[Achievement.firstSpark],
    );
    expect(service.isUnlocked(Achievement.firstSpark), isTrue);

    // Re-evaluating the same state reports nothing (idempotent).
    expect(service.evaluate(_statsWith(totalSystemEvents: 1)), isEmpty);
  });

  test('reports several badges crossed on the same tick together', () async {
    final AchievementService service = AchievementService();
    await service.init();

    expect(service.evaluate(_statsWith()), isEmpty);

    final List<Achievement> reported = service.evaluate(
      _statsWith(
        totalSystemEvents: 1,
        shinyEncounters: 1,
        level: AnchwattSettings.hardcoreUnlockLevel,
      ),
    );

    expect(
      reported,
      containsAll(<Achievement>[
        Achievement.firstSpark,
        Achievement.chromatic,
        Achievement.welcomeToHell,
      ]),
    );
    expect(reported.length, 3);
  });

  test('reset clears unlocked badges and reseeds to all-locked', () async {
    final AchievementService service = AchievementService();
    await service.init();

    service.evaluate(_statsWith());
    service.evaluate(_statsWith(totalSystemEvents: 1));
    expect(service.isUnlocked(Achievement.firstSpark), isTrue);

    await service.reset();

    // Evaluating the now-empty stats reseeds silently (no report), and every
    // badge is back to locked.
    expect(service.evaluate(_statsWith()), isEmpty);
    for (final Achievement achievement in Achievement.values) {
      expect(service.isUnlocked(achievement), isFalse);
    }
  });

  test('persists the unlocked set and the seeded flag across instances', () async {
    final AchievementService service = AchievementService();
    await service.init();

    service.evaluate(_statsWith()); // seed
    service.evaluate(_statsWith(totalSystemEvents: 1)); // unlock firstSpark

    // Let the fire-and-forget writes settle before reopening.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final AchievementService reopened = AchievementService();
    await reopened.init();

    expect(reopened.isUnlocked(Achievement.firstSpark), isTrue);

    // The seeded flag also survived: a newly satisfied badge is reported (not
    // silently seeded again) on the reopened instance.
    expect(
      reopened.evaluate(_statsWith(totalSystemEvents: 1, shinyEncounters: 1)),
      <Achievement>[Achievement.chromatic],
    );
  });
}
