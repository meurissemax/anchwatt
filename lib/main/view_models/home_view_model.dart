import 'package:anchwatt/main/models.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  /* Variables */

  int _level = AnchwattSettings.levelMin;
  int _xp = 0;

  /* Getters */

  int get level => _level;
  int get xp => _xp;
  EvolutionStage get stage => EvolutionStage.fromLevel(_level);
  double get progress => (_xp / AnchwattSettings.xpPerLevel).clamp(0, 1);

  /* Methods */

  void addXp([int amount = AnchwattSettings.xpPerEvent]) {
    _xp += amount;

    while (_xp >= AnchwattSettings.xpPerLevel && _level < AnchwattSettings.levelMax) {
      _xp -= AnchwattSettings.xpPerLevel;
      _level += 1;
    }

    if (_level >= AnchwattSettings.levelMax) {
      _level = AnchwattSettings.levelMax;
      _xp = AnchwattSettings.xpPerLevel;
    }

    notifyListeners();
  }
}
