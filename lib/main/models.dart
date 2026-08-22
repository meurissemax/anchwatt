import 'dart:math';

import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:material_ui/material_ui.dart';

// Clément, don't read this, you curious boy
class AnchwattSettings {
  // Duration-multiplier tiers. Bounds are inclusive on the low side
  // (`<= _shortMaxDurationMs` → x1) and were picked from the tercile
  // distribution of the shipped sounds, each landing in a natural gap of that
  // distribution so the tiers stay stable against small re-encodes.
  static const int _shortMaxDurationMs = 1500;
  static const int _mediumMaxDurationMs = 3000;
  static const double _shortDurationMultiplier = 1;
  static const double _mediumDurationMultiplier = 1.25;
  static const double _longDurationMultiplier = 1.5;

  static const int achievementPetsThreshold = 500;
  static const int achievementTotalEventsThreshold = 1000;
  static const int evolutionLamperoieLevel = 15;
  static const int evolutionOhmassacreLevel = 40;
  static const int hardcoreUnlockLevel = 50;
  static const double hardcoreXpMultiplier = 2;
  static const int levelMax = 100;
  static const int levelMin = 1;
  static const double levelXpCoef = 0.40;
  static const double maxVolumeMultiplier = 1.5;
  static const int petCryCooldownMaxSeconds = 4;
  static const int petCryCooldownMinSeconds = 2;
  static const double petVolumeFloor = 0.2;
  static const int randomSoundExclusionWindow = 3;
  static const Duration shinyDuration = Duration(minutes: 30);
  static const double shinyHueRotationDegrees = 150;
  static const int shinyOdds = 128;
  static const int statsCardTaglineCount = 3;
  static const int xpBase = 50;
  static const int xpGrowthFactor = 2;
  // Cross-event coalescing window. A single physical action (e.g. plugging in
  // a USB-C dock) can fan out into several system events almost simultaneously
  // — USB + display + sometimes audio — and we only want one Anchwatt reaction
  // for the whole burst. Leading-edge: the first event in the window plays a
  // sound and grants XP, the rest are absorbed.
  static const Duration systemEventCoalesceWindow = Duration(milliseconds: 500);

  static const Map<AnchwattEventType, double> baseXpByEvent = {
    AnchwattEventType.pet: 3.0,
    AnchwattEventType.usbToggle: 25.0,
    AnchwattEventType.chargerToggle: 25.0,
    AnchwattEventType.externalDisplayToggle: 25.0,
    AnchwattEventType.headphonesToggle: 25.0,
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

  // Rolls a shiny encounter: a 1-in-[shinyOdds] chance. Kept pure (takes the
  // RNG) so the odds are unit-testable with a deterministic [Random].
  static bool rollShiny(Random random) => random.nextInt(shinyOdds) == 0;

  // Whether a shiny window is active: a window exists and [now] is strictly
  // before its end (the expiry instant itself already counts as expired).
  // Kept pure (takes the clock reading) so the boundary is unit-testable
  // without real waits.
  static bool isShinyActive({required DateTime? expiresAt, required DateTime now}) =>
      expiresAt != null && now.isBefore(expiresAt);

  // Picks which footer tagline the share card shows. Kept pure (takes the RNG)
  // so the selection is unit-testable with a deterministic [Random].
  static int pickTaglineIndex(Random random) => random.nextInt(statsCardTaglineCount);

  /// Returns the XP multiplier for a sound of the given nominal duration.
  /// Falls back to 1.0 for unknown or non-positive durations.
  ///
  /// Bounds are inclusive on the low side: `durationMs <= _shortMaxDurationMs`
  /// yields x1, then `<= _mediumMaxDurationMs` yields x1.25, and anything
  /// longer yields x1.5.
  static double durationMultiplier(int durationMs) {
    if (durationMs <= _shortMaxDurationMs) {
      return _shortDurationMultiplier;
    }

    if (durationMs <= _mediumMaxDurationMs) {
      return _mediumDurationMultiplier;
    }

    return _longDurationMultiplier;
  }

  // Volume = 0 yields 0 XP for non-pet events. Fully-silenced speakers are
  // gated upstream by the ViewModel (treated exactly like DND), so this path
  // only matters when the volume drops to zero mid-playback. The pet uses
  // [petVolumeFloor] so a low-but-audible volume still grants a small gain.
  // [durationMs] is the played sound's nominal duration; 0 (no sound, or an
  // asset missing from the generated manifest) resolves to a x1 multiplier.
  static int xpForEvent({
    required AnchwattEventType type,
    required int level,
    required SoundMode mode,
    required int durationMs,
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
    final double durationMult = durationMultiplier(durationMs);

    // Single rounding, at the very end of the multiplier chain.
    return (base * levelMult * volumeMult * modeMult * durationMult).round();
  }
}

enum AnchwattEventType {
  pet,
  usbToggle,
  chargerToggle,
  externalDisplayToggle,
  headphonesToggle;

  String label(L10n l10n) {
    switch (this) {
      case AnchwattEventType.pet:
        return l10n.eventTypePet;

      case AnchwattEventType.usbToggle:
        return l10n.eventTypeUsbToggle;

      case AnchwattEventType.chargerToggle:
        return l10n.eventTypeChargerToggle;

      case AnchwattEventType.externalDisplayToggle:
        return l10n.eventTypeExternalDisplayToggle;

      case AnchwattEventType.headphonesToggle:
        return l10n.eventTypeHeadphonesToggle;
    }
  }
}

enum Evolution {
  anchwatt,
  lamperoie,
  ohmassacre;

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

  String flavor(L10n l10n) {
    switch (this) {
      case Evolution.anchwatt:
        return l10n.evolutionFlavorAnchwatt;

      case Evolution.lamperoie:
        return l10n.evolutionFlavorLamperoie;

      case Evolution.ohmassacre:
        return l10n.evolutionFlavorOhmassacre;
    }
  }
}

enum SoundMode {
  corporate,
  friday,
  hardcore;

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

      case SoundMode.hardcore:
        return colorSoundModeHardcore;
    }
  }

  String get assetSubfolder {
    switch (this) {
      case SoundMode.corporate:
        return 'corporate/';

      case SoundMode.friday:
        return 'friday/';

      case SoundMode.hardcore:
        return 'hardcore/';
    }
  }

  IconData get iconData {
    switch (this) {
      case SoundMode.corporate:
        return Icons.business_center;

      case SoundMode.friday:
        return Icons.local_bar;

      case SoundMode.hardcore:
        return Icons.local_fire_department;
    }
  }

  // Cycles Corporate → Friday → Hardcore → Corporate. Locking (Hardcore below
  // its unlock level) is a business rule applied by the ViewModel, not here.
  SoundMode get next {
    switch (this) {
      case SoundMode.corporate:
        return SoundMode.friday;

      case SoundMode.friday:
        return SoundMode.hardcore;

      case SoundMode.hardcore:
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

      case SoundMode.hardcore:
        return AnchwattSettings.hardcoreXpMultiplier;
    }
  }

  String label(L10n l10n) {
    switch (this) {
      case SoundMode.corporate:
        return l10n.soundModeCorporate;

      case SoundMode.friday:
        return l10n.soundModeFriday;

      case SoundMode.hardcore:
        return l10n.soundModeHardcore;
    }
  }

  String tooltip(L10n l10n) => l10n.soundModeTooltip(label(l10n));
}

// Immutable snapshot of the stats an [Achievement] predicate reads. Composed by
// the orchestrating ViewModel from [StatsService] counters plus the current
// level (which lives on the ViewModel, not the stats service), so the catalogue
// predicates stay pure and testable without touching any service.
@immutable
class AchievementStats {
  final int totalSystemEvents;
  final int petInteractions;
  final int shinyEncounters;
  final int level;

  const AchievementStats({
    required this.totalSystemEvents,
    required this.petInteractions,
    required this.shinyEncounters,
    required this.level,
  });
}

// Badge catalogue. Each entry is a pure threshold predicate over an
// [AchievementStats] snapshot, plus its presentation (icon, accent colour, and
// localized label/description). The enum name is the stable id persisted by
// AchievementStorage, so entries must never be renamed once shipped.
enum Achievement {
  firstSpark,
  chromatic,
  welcomeToHell,
  workhorse,
  compulsivePetter,
  endOfLine;

  IconData get iconData {
    switch (this) {
      case Achievement.firstSpark:
        return Icons.bolt;

      case Achievement.chromatic:
        return Icons.palette;

      case Achievement.welcomeToHell:
        return Icons.local_fire_department;

      case Achievement.workhorse:
        return Icons.engineering;

      case Achievement.compulsivePetter:
        return Icons.pets;

      case Achievement.endOfLine:
        return Icons.emoji_events;
    }
  }

  Color get accentColor {
    switch (this) {
      case Achievement.firstSpark:
        return colorEvolutionAnchwatt;

      case Achievement.chromatic:
        return colorEvolutionOhmassacre;

      case Achievement.welcomeToHell:
        return colorSoundModeHardcore;

      case Achievement.workhorse:
        return colorEvolutionLamperoie;

      case Achievement.compulsivePetter:
        return colorSoundModeFriday;

      case Achievement.endOfLine:
        return colorLevelMaxGold;
    }
  }

  String label(L10n l10n) {
    switch (this) {
      case Achievement.firstSpark:
        return l10n.achievementFirstSparkLabel;

      case Achievement.chromatic:
        return l10n.achievementChromaticLabel;

      case Achievement.welcomeToHell:
        return l10n.achievementWelcomeToHellLabel;

      case Achievement.workhorse:
        return l10n.achievementWorkhorseLabel;

      case Achievement.compulsivePetter:
        return l10n.achievementCompulsivePetterLabel;

      case Achievement.endOfLine:
        return l10n.achievementEndOfLineLabel;
    }
  }

  String description(L10n l10n) {
    switch (this) {
      case Achievement.firstSpark:
        return l10n.achievementFirstSparkDescription;

      case Achievement.chromatic:
        return l10n.achievementChromaticDescription;

      case Achievement.welcomeToHell:
        return l10n.achievementWelcomeToHellDescription;

      case Achievement.workhorse:
        return l10n.achievementWorkhorseDescription;

      case Achievement.compulsivePetter:
        return l10n.achievementCompulsivePetterDescription;

      case Achievement.endOfLine:
        return l10n.achievementEndOfLineDescription;
    }
  }

  bool isUnlockedBy(AchievementStats stats) {
    switch (this) {
      case Achievement.firstSpark:
        return stats.totalSystemEvents >= 1;

      case Achievement.chromatic:
        return stats.shinyEncounters >= 1;

      case Achievement.welcomeToHell:
        return stats.level >= AnchwattSettings.hardcoreUnlockLevel;

      case Achievement.workhorse:
        return stats.totalSystemEvents >= AnchwattSettings.achievementTotalEventsThreshold;

      case Achievement.compulsivePetter:
        return stats.petInteractions >= AnchwattSettings.achievementPetsThreshold;

      case Achievement.endOfLine:
        return stats.level >= AnchwattSettings.levelMax;
    }
  }
}

// Immutable snapshot the shareable stats card renders from. Built once at
// capture time from the live services so the captured frame never listens to
// anything. [isShiny] freezes whether a shiny window was active at capture
// time — the card draws the recoloured sprite when true (and only the sprite:
// no extra shiny marker) — and [tagline] is the already-localized footer line
// with its {level} placeholder filled in.
@immutable
class StatsCardData {
  final int level;
  final int xpInLevel;
  final int xpForLevel;
  final Evolution evolution;
  final bool isShiny;
  final int totalSystemEvents;
  final int petInteractions;
  final int shinyEncounters;
  final DateTime memberSince;
  final List<Achievement> unlockedBadges;
  final String tagline;

  const StatsCardData({
    required this.level,
    required this.xpInLevel,
    required this.xpForLevel,
    required this.evolution,
    required this.isShiny,
    required this.totalSystemEvents,
    required this.petInteractions,
    required this.shinyEncounters,
    required this.memberSince,
    required this.unlockedBadges,
    required this.tagline,
  });
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

// Emitted by `CalendarAutoMuteService` only on transitions caused by the real
// timing of a calendar event (event start, event end) — never on user-driven
// transitions (the user toggling DND off mid-event, or that override expiring).
// The distinction matters for the notification trigger: we only fire a notif
// for transitions the user did not initiate themselves.
sealed class CalendarMuteTransition {
  const CalendarMuteTransition();
}

class CalendarMuteActivated extends CalendarMuteTransition {
  final BusyEvent event;

  const CalendarMuteActivated({
    required this.event,
  });
}

class CalendarMuteDeactivated extends CalendarMuteTransition {
  final BusyEvent endedEvent;

  const CalendarMuteDeactivated({
    required this.endedEvent,
  });
}

enum NotificationServiceError {
  permissionDenied,
  initFailed,
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

  // Muted or fully turned down — the single predicate behind the event gating
  // (silenced speakers are treated exactly like DND) and the red volume pill.
  bool get isSilenced => muted || volume <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SystemVolumeState && other.volume == volume && other.muted == muted);

  @override
  int get hashCode => Object.hash(volume, muted);
}
