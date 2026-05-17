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
  static const int petCryCooldownMaxSeconds = 4;
  static const int petCryCooldownMinSeconds = 2;
  static const double petVolumeFloor = 0.2;
  static const int randomSoundExclusionWindow = 3;
  static const int xpBase = 25;
  static const int xpGrowthFactor = 2;
  // Cross-event coalescing window. A single physical action (e.g. plugging in
  // a USB-C dock) can fan out into several system events almost simultaneously
  // — USB + display + sometimes audio — and we only want one Anchwatt reaction
  // for the whole burst. Leading-edge: the first event in the window plays a
  // sound and grants XP, the rest are absorbed.
  static const Duration systemEventCoalesceWindow = Duration(milliseconds: 500);

  static const Map<AnchwattEventType, double> baseXpByEvent = {
    AnchwattEventType.pet: 2.0,
    AnchwattEventType.usbToggle: 20.0,
    AnchwattEventType.chargerToggle: 20.0,
    AnchwattEventType.externalDisplayToggle: 20.0,
    AnchwattEventType.headphonesToggle: 20.0,
  };

  static const Set<AnchwattEventType> volumeAffectedEvents = {
    AnchwattEventType.pet,
    AnchwattEventType.usbToggle,
    AnchwattEventType.chargerToggle,
    AnchwattEventType.externalDisplayToggle,
    AnchwattEventType.headphonesToggle,
  };

  // Events that pick a random sound — eligible for [SoundMode.xpMultiplier].
  // The pet plays Anchwatt's cry (same sound every time), so it is excluded.
  static const Set<AnchwattEventType> randomSoundEvents = {
    AnchwattEventType.usbToggle,
    AnchwattEventType.chargerToggle,
    AnchwattEventType.externalDisplayToggle,
    AnchwattEventType.headphonesToggle,
  };

  static int xpForLevel(int level) => xpBase + xpGrowthFactor * (level - 1) * (level - 1);

  // Volume = 0 yields 0 XP for non-pet events (anti-farming when muted).
  // The pet uses [petVolumeFloor] so it still grants a small gain when muted.
  static int xpForEvent({
    required AnchwattEventType type,
    required int level,
    required SoundMode mode,
    double? systemVolume,
  }) {
    final double base = baseXpByEvent[type]!;
    final double levelMult = 1 + (level - 1) * levelXpCoef;
    final bool volumeAffected = volumeAffectedEvents.contains(type);

    assert(
      !volumeAffected || systemVolume != null,
      'systemVolume is required for volume-affected events',
    );

    final double volumeFloor = type == AnchwattEventType.pet ? petVolumeFloor : 0.0;
    final double clamped = (systemVolume ?? 0.0).clamp(0.0, 1.0);
    final double volumeMult = volumeAffected
        ? (volumeFloor + (1.0 - volumeFloor) * clamped) * maxVolumeMultiplier
        : 1.0;

    final double modeMult = randomSoundEvents.contains(type) ? mode.xpMultiplier : 1.0;

    return (base * levelMult * volumeMult * modeMult).round();
  }
}

enum AnchwattEventType {
  pet,
  usbToggle,
  chargerToggle,
  externalDisplayToggle,
  headphonesToggle,
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

  // Applied to XP from [AnchwattSettings.randomSoundEvents] only — the pet
  // action is unaffected.
  double get xpMultiplier {
    switch (this) {
      case SoundMode.corporate:
        return 1;

      case SoundMode.friday:
        return 1.5;
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
class BusyEvent {
  final String id;
  final String title;
  final DateTime endTime;

  const BusyEvent({
    required this.id,
    required this.title,
    required this.endTime,
  });

  static BusyEvent? fromMap(Map<Object?, Object?> map) {
    final Object? rawId = map['id'];
    final Object? rawTitle = map['title'];
    final Object? rawEnd = map['endTime'];

    if (rawId is! String || rawId.isEmpty) {
      return null;
    }
    if (rawEnd is! int) {
      return null;
    }

    return BusyEvent(
      id: rawId,
      title: rawTitle is String ? rawTitle : '',
      endTime: DateTime.fromMillisecondsSinceEpoch(rawEnd),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusyEvent && other.id == id && other.title == title && other.endTime == endTime);

  @override
  int get hashCode => Object.hash(id, title, endTime);
}

enum CalendarAutoMuteError {
  permissionDenied,
  fetchFailed,
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
