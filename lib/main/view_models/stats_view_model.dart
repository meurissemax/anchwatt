import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/stats_service.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// Per-modal ViewModel. Reads the shared [StatsService] and the parent game
// state, then exposes a snapshot of already-formatted, already-localized values.
// The modal is passive: values are read on demand and not refreshed live.
class StatsViewModel extends ChangeNotifier {
  /* Static variables */

  static final L10n _l10n = locator<L10n>();
  static final DateFormat _memberSinceFormat = DateFormat('dd/MM/yyyy');

  /* Variables */

  final AnchwattViewModel _parent;
  final StatsService _statsService = locator<StatsService>();

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

  String get soundsSplit => _l10n.statsSoundsSplit(
    _statsService.soundsPlayedFor(SoundMode.corporate),
    _statsService.soundsPlayedFor(SoundMode.friday),
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
}
