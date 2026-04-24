import 'package:anchwatt/main/models.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  /* Static variables */

  static const Duration defaultLevelUpDwell = Duration(milliseconds: 500);

  /* Variables */

  final Duration _levelUpDwell;
  int _level = AnchwattSettings.levelMin;
  int _xp = 0;
  Future<void>? _pending;

  /* Constructor */

  HomeViewModel({Duration levelUpDwell = defaultLevelUpDwell}) : _levelUpDwell = levelUpDwell;

  /* Getters */

  int get level => _level;
  int get xp => _xp;
  int get xpToNextLevel => AnchwattSettings.xpForLevel(_level);
  Evolution get evolution => Evolution.fromLevel(_level);
  double get progress => (_xp / xpToNextLevel).clamp(0, 1);

  /* Methods */

  Future<void> addXp([int amount = AnchwattSettings.xpPerEvent]) {
    final Future<void> next = (_pending ?? Future<void>.value()).then((_) => _process(amount));
    _pending = next;

    next.whenComplete(() {
      if (identical(_pending, next)) {
        _pending = null;
      }
    });

    return next;
  }

  Future<void> _process(int amount) async {
    if (_level >= AnchwattSettings.levelMax) {
      return;
    }

    _xp += amount;

    while (_xp >= AnchwattSettings.xpForLevel(_level) && _level < AnchwattSettings.levelMax) {
      final int cost = AnchwattSettings.xpForLevel(_level);
      final int carry = _xp - cost;

      _xp = cost;
      notifyListeners();

      await Future<void>.delayed(_levelUpDwell);

      _level += 1;
      _xp = carry;
    }

    if (_level >= AnchwattSettings.levelMax) {
      _level = AnchwattSettings.levelMax;
      _xp = AnchwattSettings.xpForLevel(AnchwattSettings.levelMax);
    }

    notifyListeners();
  }
}
