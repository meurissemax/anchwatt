import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Total XP earned to reach (level, xp) from a fresh character — the sum of
// every completed palier plus the current in-palier progress. Used to assert
// that no XP is silently dropped by the grant pipeline.
int _totalXp(int level, int xp) {
  int total = xp;

  for (int l = AnchwattSettings.levelMin; l < level; l++) {
    total += AnchwattSettings.xpForLevel(l);
  }

  return total;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    setupLocator();
  });

  test('AnchwattViewModel addXp crosses evolution boundaries and caps at levelMax', () async {
    final AnchwattViewModel vm = AnchwattViewModel();

    expect(vm.level, AnchwattSettings.levelMin);
    expect(vm.evolution, Evolution.anchwatt);

    while (vm.level < AnchwattSettings.evolutionLamperoieLevel) {
      await vm.addXp(vm.xpToNextLevel);
    }

    expect(vm.level, AnchwattSettings.evolutionLamperoieLevel);
    expect(vm.evolution, Evolution.lamperoie);

    while (vm.level < AnchwattSettings.evolutionOhmassacreLevel) {
      await vm.addXp(vm.xpToNextLevel);
    }

    expect(vm.level, AnchwattSettings.evolutionOhmassacreLevel);
    expect(vm.evolution, Evolution.ohmassacre);

    for (int i = 0; i < AnchwattSettings.levelMax; i++) {
      await vm.addXp(AnchwattSettings.xpForLevel(AnchwattSettings.levelMax));
    }

    expect(vm.level, AnchwattSettings.levelMax);
    expect(vm.xp, AnchwattSettings.xpForLevel(AnchwattSettings.levelMax));
    expect(vm.progress, 1);
  });

  // Guards the regression where a level-up blocked the serialized grant pipeline
  // (a 500ms dwell inside _process): a burst of rapid, un-awaited grants — the
  // way pet + system events pile up — must all land, never freeze, never drop.
  test('AnchwattViewModel processes a burst of un-awaited grants without losing XP', () async {
    final AnchwattViewModel vm = AnchwattViewModel();

    // Let _bootServices() run its one-time progression read before the burst so
    // it cannot race (and clobber) the grants below.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    const int grantAmount = 200;
    const int grantCount = 10;

    final List<Future<void>> grants = [
      for (int i = 0; i < grantCount; i++) vm.addXp(grantAmount),
    ];
    await Future.wait(grants);

    expect(vm.level, greaterThan(AnchwattSettings.levelMin));
    expect(_totalXp(vm.level, vm.xp), grantAmount * grantCount);
  });
}
