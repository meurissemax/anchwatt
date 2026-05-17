import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('shouldNotifyLevelUp', () {
    test('fires only when notifications enabled, DND off, window hidden', () {
      expect(
        AnchwattViewModel.shouldNotifyLevelUp(
          notificationsEnabled: true,
          silentModeEnabled: false,
          windowHidden: true,
        ),
        true,
      );
    });

    test('does not fire when notifications are disabled', () {
      for (final bool dnd in <bool>[true, false]) {
        for (final bool hidden in <bool>[true, false]) {
          expect(
            AnchwattViewModel.shouldNotifyLevelUp(
              notificationsEnabled: false,
              silentModeEnabled: dnd,
              windowHidden: hidden,
            ),
            false,
            reason: 'enabled=false, dnd=$dnd, hidden=$hidden should not fire',
          );
        }
      }
    });

    test('does not fire when DND is on', () {
      for (final bool hidden in <bool>[true, false]) {
        expect(
          AnchwattViewModel.shouldNotifyLevelUp(
            notificationsEnabled: true,
            silentModeEnabled: true,
            windowHidden: hidden,
          ),
          false,
          reason: 'dnd=true, hidden=$hidden should not fire',
        );
      }
    });

    test('does not fire when the window is visible', () {
      expect(
        AnchwattViewModel.shouldNotifyLevelUp(
          notificationsEnabled: true,
          silentModeEnabled: false,
          windowHidden: false,
        ),
        false,
      );
    });
  });

  test('AnchwattViewModel addXp crosses evolution boundaries and caps at levelMax', () async {
    final AnchwattViewModel vm = AnchwattViewModel(
      levelUpDwell: Duration.zero,
    );

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
}
