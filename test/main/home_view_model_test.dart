import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomeViewModel addXp crosses stage boundaries and caps at levelMax', () {
    final HomeViewModel vm = HomeViewModel();

    expect(vm.level, AnchwattSettings.levelMin);
    expect(vm.stage, EvolutionStage.baby);

    for (int i = 0; i < 33; i++) {
      vm.addXp(AnchwattSettings.xpPerLevel);
    }

    expect(vm.level, 34);
    expect(vm.stage, EvolutionStage.normal);

    for (int i = 0; i < 33; i++) {
      vm.addXp(AnchwattSettings.xpPerLevel);
    }

    expect(vm.level, 67);
    expect(vm.stage, EvolutionStage.mega);

    for (int i = 0; i < 200; i++) {
      vm.addXp(AnchwattSettings.xpPerLevel);
    }

    expect(vm.level, AnchwattSettings.levelMax);
    expect(vm.xp, AnchwattSettings.xpPerLevel);
    expect(vm.progress, 1);
  });
}
