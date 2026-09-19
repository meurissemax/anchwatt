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

  // Installs predating cycles have no cycle key at all: they must read as 0 and
  // present the app exactly as before.
  test('readCycleCount reads 0 when the key is absent', () async {
    final AnchwattStorage storage = AnchwattStorage();
    await storage.init();

    expect(storage.readCycleCount(), 0);
  });

  test('readCycleCount round-trips a written count and clamps a negative one', () async {
    final AnchwattStorage storage = AnchwattStorage();
    await storage.init();

    await storage.writeCycleCount(4);
    expect(storage.readCycleCount(), 4);

    await storage.writeCycleCount(-1);
    expect(storage.readCycleCount(), 0);
  });

  // The cycle count lives outside the level/xp validation: a corrupted
  // progression resets to level 1 but never erases the cycles earned.
  test('readCycleCount survives a progression that fails validation', () async {
    final AnchwattStorage storage = AnchwattStorage();
    await storage.init();

    await storage.writeCycleCount(2);
    await storage.writeProgression(
      level: AnchwattSettings.levelMax + 1,
      xp: 0,
    );

    expect(storage.readProgression().level, AnchwattSettings.levelMin);
    expect(storage.readCycleCount(), 2);
  });

  test('clear removes the cycle count with the rest of the progression', () async {
    final AnchwattStorage storage = AnchwattStorage();
    await storage.init();

    await storage.writeCycleCount(3);
    await storage.clear();

    expect(storage.readCycleCount(), 0);
  });
}
