import 'dart:async';

import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/stats_service.dart';
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

  // At the cap, a further grant is a no-op for progression (level and xp stay
  // frozen) and must not fire the XP-gain floater — its stream stays silent.
  // The lifetime-XP stat keeps accumulating though: events still happen at 100,
  // so their tallies must not desync from the sounds that play.
  test('AnchwattViewModel discards XP at max level but keeps the lifetime stat counting', () async {
    final StatsService stats = locator<StatsService>();
    final AnchwattViewModel vm = AnchwattViewModel();

    // Let _bootServices() finish its progression read and stats init before the
    // grants, so neither races and clobbers the state asserted below.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    while (vm.level < AnchwattSettings.levelMax) {
      await vm.addXp(vm.xpToNextLevel);
    }

    expect(vm.isMaxLevel, isTrue);

    final int cappedXp = vm.xp;
    final int lifetimeBefore = stats.lifetimeXp;
    final List<int> gains = <int>[];
    final StreamSubscription<int> subscription = vm.xpGainStream.listen(gains.add);

    await vm.addXp(500);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(vm.level, AnchwattSettings.levelMax);
    expect(vm.xp, cappedXp);
    expect(gains, isEmpty);
    expect(stats.lifetimeXp, lifetimeBefore + 500);
  });
}
