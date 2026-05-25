import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
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
