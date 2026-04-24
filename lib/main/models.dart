import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:flutter/material.dart';

class AnchwattSettings {
  static const int levelMax = 100;
  static const int levelMin = 1;
  static const int xpPerEvent = 10;
  static const int xpPerLevel = 100;
}

enum EvolutionStage {
  baby,
  normal,
  mega
  ;

  static EvolutionStage fromLevel(int level) {
    if (level <= 33) {
      return EvolutionStage.baby;
    }

    if (level <= 66) {
      return EvolutionStage.normal;
    }

    return EvolutionStage.mega;
  }

  Color get accentColor {
    switch (this) {
      case EvolutionStage.baby:
        return colorStageBaby;

      case EvolutionStage.normal:
        return colorStageNormal;

      case EvolutionStage.mega:
        return colorStageMega;
    }
  }

  double get scale {
    switch (this) {
      case EvolutionStage.baby:
        return 0.55;

      case EvolutionStage.normal:
        return 0.8;

      case EvolutionStage.mega:
        return 1;
    }
  }

  double get opacity {
    switch (this) {
      case EvolutionStage.baby:
        return 0.8;

      case EvolutionStage.normal:
        return 1;

      case EvolutionStage.mega:
        return 1;
    }
  }

  String label(L10n l10n) {
    switch (this) {
      case EvolutionStage.baby:
        return l10n.stageBaby;

      case EvolutionStage.normal:
        return l10n.stageNormal;

      case EvolutionStage.mega:
        return l10n.stageMega;
    }
  }
}
