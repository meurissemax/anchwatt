import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:flutter/material.dart';

// Clément, don't read this, you curious boy
class AnchwattSettings {
  static const int evolutionLamperoieLevel = 15;
  static const int evolutionOhmassacreLevel = 40;
  static const int levelMax = 100;
  static const int levelMin = 1;
  static const double levelXpCoef = 0.30;
  static const double maxVolumeMultiplier = 1.5;
  static const int petCryCooldownMaxSeconds = 9;
  static const int petCryCooldownMinSeconds = 5;
  static const int petXpCooldownMaxSeconds = 5;
  static const int petXpCooldownMinSeconds = 3;
  static const int xpBase = 25;
  static const int xpGrowthFactor = 2;

  static const Map<AnchwattEventType, double> baseXpByEvent = {
    AnchwattEventType.pet: 2.0,
    AnchwattEventType.usbToggle: 20.0,
  };

  static const Set<AnchwattEventType> volumeAffectedEvents = {
    AnchwattEventType.usbToggle,
  };

  static int xpForLevel(int level) => xpBase + xpGrowthFactor * (level - 1) * (level - 1);

  // Volume = 0 yields 0 XP — intentional (prevents farming with the system muted).
  static int xpForEvent({
    required AnchwattEventType type,
    required int level,
    double? systemVolume,
  }) {
    final double base = baseXpByEvent[type]!;
    final double levelMult = 1 + (level - 1) * levelXpCoef;
    final bool volumeAffected = volumeAffectedEvents.contains(type);

    assert(
      !volumeAffected || systemVolume != null,
      'systemVolume is required for volume-affected events',
    );

    final double volumeMult = volumeAffected ? systemVolume!.clamp(0.0, 1.0) * maxVolumeMultiplier : 1.0;

    return (base * levelMult * volumeMult).round();
  }
}

enum AnchwattEventType {
  pet,
  usbToggle,
}

enum Evolution {
  anchwatt,
  lamperoie,
  ohmassacre
  ;

  static Evolution fromLevel(int level) {
    if (level < AnchwattSettings.evolutionLamperoieLevel) {
      return Evolution.anchwatt;
    }

    if (level < AnchwattSettings.evolutionOhmassacreLevel) {
      return Evolution.lamperoie;
    }

    return Evolution.ohmassacre;
  }

  Color get accentColor {
    switch (this) {
      case Evolution.anchwatt:
        return colorEvolutionAnchwatt;

      case Evolution.lamperoie:
        return colorEvolutionLamperoie;

      case Evolution.ohmassacre:
        return colorEvolutionOhmassacre;
    }
  }

  String get assetPath {
    switch (this) {
      case Evolution.anchwatt:
        return 'assets/images/misc/anchwatt.png';

      case Evolution.lamperoie:
        return 'assets/images/misc/lamperoie.png';

      case Evolution.ohmassacre:
        return 'assets/images/misc/ohmassacre.png';
    }
  }

  String label(L10n l10n) {
    switch (this) {
      case Evolution.anchwatt:
        return l10n.anchwatt;

      case Evolution.lamperoie:
        return l10n.lamperoie;

      case Evolution.ohmassacre:
        return l10n.ohmassacre;
    }
  }
}

enum SoundMode {
  corporate,
  friday
  ;

  static SoundMode fromName(String? name) {
    for (final SoundMode mode in SoundMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }

    return SoundMode.corporate;
  }

  Color get accentColor {
    switch (this) {
      case SoundMode.corporate:
        return colorSoundModeCorporate;

      case SoundMode.friday:
        return colorSoundModeFriday;
    }
  }

  String get assetSubfolder {
    switch (this) {
      case SoundMode.corporate:
        return 'corporate/';

      case SoundMode.friday:
        return 'friday/';
    }
  }

  IconData get iconData {
    switch (this) {
      case SoundMode.corporate:
        return Icons.business_center;

      case SoundMode.friday:
        return Icons.local_bar;
    }
  }

  SoundMode get next {
    switch (this) {
      case SoundMode.corporate:
        return SoundMode.friday;

      case SoundMode.friday:
        return SoundMode.corporate;
    }
  }

  String label(L10n l10n) {
    switch (this) {
      case SoundMode.corporate:
        return l10n.soundModeCorporate;

      case SoundMode.friday:
        return l10n.soundModeFriday;
    }
  }

  String switchTooltip(L10n l10n) {
    switch (this) {
      case SoundMode.corporate:
        return l10n.soundModeSwitchToFriday;

      case SoundMode.friday:
        return l10n.soundModeSwitchToCorporate;
    }
  }
}

class SystemVolumeSettings {
  static const double lowThreshold = 0.15;
  static const double mediumThreshold = 0.5;
}

@immutable
class SystemVolumeState {
  final double volume;
  final bool muted;

  const SystemVolumeState({
    required this.volume,
    required this.muted,
  });

  factory SystemVolumeState.initial() => const SystemVolumeState(
    volume: 0,
    muted: false,
  );

  factory SystemVolumeState.fromMap(Map<Object?, Object?> map) {
    final Object? rawVolume = map['volume'];
    final Object? rawMuted = map['muted'];

    double volume = rawVolume is num ? rawVolume.toDouble() : 0;
    if (volume.isNaN || volume < 0) {
      volume = 0;
    } else if (volume > 1) {
      volume = 1;
    }

    return SystemVolumeState(
      volume: volume,
      muted: rawMuted is bool && rawMuted,
    );
  }

  int get percent => (volume * 100).round();
  bool get isLow => !muted && volume < SystemVolumeSettings.lowThreshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SystemVolumeState && other.volume == volume && other.muted == muted);

  @override
  int get hashCode => Object.hash(volume, muted);
}
