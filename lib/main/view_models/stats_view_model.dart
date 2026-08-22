import 'dart:async';
import 'dart:math';

import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/achievement_service.dart';
import 'package:anchwatt/main/services/share_card_service.dart';
import 'package:anchwatt/main/services/stats_service.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// Drives the "Partager la carte" button, which lacks any app-wide toast to lean
// on: the button reflects each state itself, and [copied]/[error] auto-settle
// back to [idle] after a short delay.
enum ShareStatus { idle, working, copied, error }

// Per-modal ViewModel. Reads the shared [StatsService] and the parent game
// state, then exposes a snapshot of already-formatted, already-localized values.
// The modal is passive: values are read on demand and not refreshed live.
class StatsViewModel extends ChangeNotifier {
  /* Static variables */

  static final L10n _l10n = locator<L10n>();
  static final DateFormat _memberSinceFormat = DateFormat('dd/MM/yyyy');
  static const Duration _shareStatusResetDelay = Duration(seconds: 3);

  /* Variables */

  final AnchwattViewModel _parent;
  final StatsService _statsService = locator<StatsService>();
  final AchievementService _achievementService = locator<AchievementService>();
  final ShareCardService _shareCardService = ShareCardService();

  ShareStatus _shareStatus = ShareStatus.idle;
  Timer? _shareStatusResetTimer;

  /* Constructor */

  StatsViewModel(this._parent);

  /* Getters */

  Evolution get evolution => _parent.evolution;
  String get stageLabel => _parent.evolution.label(_l10n);
  String get stageFlavor => _parent.evolution.flavor(_l10n);

  int get level => _parent.level;
  int get lifetimeXp => _statsService.lifetimeXp;
  int get totalWakeups => _statsService.totalSystemEvents;
  int get soundsPlayed => _statsService.soundsPlayed;
  int get petPokes => _statsService.petInteractions;
  int get shinyEncounters => _statsService.shinyEncounters;

  ShareStatus get shareStatus => _shareStatus;

  // The full catalogue with each badge's current unlock state, read once when
  // the modal opens (like every other value here). Locked badges are rendered
  // greyed with their condition, so the whole list is always exposed.
  List<({Achievement achievement, bool unlocked})> get achievements => Achievement.values
      .map(
        (Achievement achievement) => (
          achievement: achievement,
          unlocked: _achievementService.isUnlocked(achievement),
        ),
      )
      .toList();

  String get soundsSplit => _l10n.statsSoundsSplit(
    formatNumber(_statsService.soundsPlayedFor(SoundMode.corporate)),
    formatNumber(_statsService.soundsPlayedFor(SoundMode.friday)),
    formatNumber(_statsService.soundsPlayedFor(SoundMode.hardcore)),
  );

  String get memberSince => _memberSinceFormat.format(
    _statsService.firstLaunchDate ?? DateTime.now(),
  );

  String get favoriteEventLabel {
    final AnchwattEventType? favorite = _favoriteEvent();

    if (favorite == null) {
      return _l10n.statsFavoriteEventEmpty;
    }

    return favorite.label(_l10n);
  }

  /* Methods */

  // Argmax over the system events only — the pet is tracked separately and must
  // never win. Returns null when no system event has fired yet (all counts 0),
  // which the getter renders as the localized empty-state fallback. Ties resolve
  // to the first match in enum order.
  AnchwattEventType? _favoriteEvent() {
    AnchwattEventType? best;
    int bestCount = 0;

    for (final AnchwattEventType type in AnchwattEventType.values) {
      if (type == AnchwattEventType.pet) {
        continue;
      }

      final int count = _statsService.eventCount(type);

      if (count > bestCount) {
        bestCount = count;
        best = type;
      }
    }

    return best;
  }

  // Assembles the snapshot the share card renders from, read once at capture
  // time. Level/XP/evolution come from the parent game state; the counters from
  // the stats service; the badges from the achievement catalogue. The shiny
  // flag freezes whether a shiny window is active right now, so a card shared
  // mid-window carries the recoloured sprite.
  StatsCardData buildCardData() {
    final int level = _parent.level;

    return StatsCardData(
      level: level,
      xpInLevel: _parent.xp,
      xpForLevel: _parent.xpToNextLevel,
      evolution: _parent.evolution,
      isShiny: _parent.isShiny,
      totalSystemEvents: _statsService.totalSystemEvents,
      petInteractions: _statsService.petInteractions,
      shinyEncounters: _statsService.shinyEncounters,
      memberSince: _statsService.firstLaunchDate ?? DateTime.now(),
      unlockedBadges: Achievement.values.where(_achievementService.isUnlocked).toList(),
      tagline: _pickTagline(level),
    );
  }

  // Picks one footer tagline at random and fills its {level} placeholder. The
  // index selection is delegated to a pure, testable helper.
  String _pickTagline(int level) {
    final String formattedLevel = formatNumber(level);

    switch (AnchwattSettings.pickTaglineIndex(Random())) {
      case 0:
        return _l10n.statsCardTaglineFirst(formattedLevel);

      case 1:
        return _l10n.statsCardTaglineSecond(formattedLevel);

      default:
        return _l10n.statsCardTaglineThird(formattedLevel);
    }
  }

  // Runs the whole share flow. [capture] renders the card to PNG bytes — it is
  // supplied by the view because the off-screen render needs a live Overlay.
  // This VM owns the surrounding orchestration and the button's status.
  Future<void> shareCard(Future<Uint8List> Function() capture) async {
    if (_shareStatus == ShareStatus.working) {
      return;
    }

    _setShareStatus(ShareStatus.working);

    try {
      final Uint8List png = await capture();
      await _shareCardService.writeTempPng(png);
      await _shareCardService.copyToClipboard(png);

      _setShareStatus(ShareStatus.copied);
    } on Object catch (error) {
      debugPrint('StatsViewModel: share card failed: $error');

      _setShareStatus(ShareStatus.error);
    }
  }

  void _setShareStatus(ShareStatus status) {
    _shareStatusResetTimer?.cancel();
    _shareStatus = status;
    notifyListeners();

    // Let a resolved outcome linger briefly, then fall back to idle so the
    // button invites another share.
    if (status == ShareStatus.copied || status == ShareStatus.error) {
      _shareStatusResetTimer = Timer(_shareStatusResetDelay, () {
        _shareStatus = ShareStatus.idle;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _shareStatusResetTimer?.cancel();
    super.dispose();
  }
}
