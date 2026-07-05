import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/anchwatt_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  // At the cap, _process persists xp == xpForLevel(levelMax) (a full bar). The
  // reader must accept that state and round-trip it, not treat it as corruption
  // and wipe a level-100 character back to level 1 on the next launch.
  test('readProgression round-trips a maxed-out character instead of resetting it', () async {
    final AnchwattStorage storage = AnchwattStorage();
    await storage.init();

    await storage.writeProgression(
      level: AnchwattSettings.levelMax,
      xp: AnchwattSettings.xpForLevel(AnchwattSettings.levelMax),
    );

    final ({int level, int xp}) restored = storage.readProgression();

    expect(restored.level, AnchwattSettings.levelMax);
    expect(restored.xp, AnchwattSettings.xpForLevel(AnchwattSettings.levelMax));
  });

  // Below the cap, xp == xpForLevel(level) would have triggered a level-up, so
  // it can never be a legitimately persisted value and is rejected.
  test('readProgression rejects an at-threshold xp below the cap', () async {
    const int level = 20;

    final AnchwattStorage storage = AnchwattStorage();
    await storage.init();

    await storage.writeProgression(
      level: level,
      xp: AnchwattSettings.xpForLevel(level),
    );

    final ({int level, int xp}) restored = storage.readProgression();

    expect(restored.level, AnchwattSettings.levelMin);
    expect(restored.xp, 0);
  });
}
