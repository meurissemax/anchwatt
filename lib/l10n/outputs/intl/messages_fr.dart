// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fr';

  static String m0(level, name) => "${name} — Lvl ${level}";

  static String m1(current, total) => "${current} / ${total}";

  static String m2(xp) => "+${xp}xp";

  static String m3(title, time) => "Activé auto : ${title} jusqu\'à ${time}";

  static String m4(title, time) =>
      "Silence pendant ${title}, jusqu\'à ${time}.";

  static String m5(title) => "${title} terminé — Anchwatt reprend du service.";

  static String m6(name) => "${name} vient d\'évoluer.";

  static String m7(version) => "v${version}";

  static String m8(version) =>
      "Une nouvelle version a pointé son nez : ${version}";

  static String m9(percent) => "Volume : ${percent} %";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "anchwatt": MessageLookupByLibrary.simpleMessage("Anchwatt"),
    "anchwattDebugAddXp": MessageLookupByLibrary.simpleMessage("Tricher : +XP"),
    "anchwattEvolutionLevel": m0,
    "anchwattXpCounter": m1,
    "anchwattXpGain": m2,
    "autoMuteActiveReason": m3,
    "autoMuteDescription": MessageLookupByLibrary.simpleMessage(
      "Branche ton calendrier pour couper Anchwatt pile pendant les réunions.",
    ),
    "autoMuteLabel": MessageLookupByLibrary.simpleMessage(
      "Silence pendant les réunions",
    ),
    "autoMuteOpenSystemSettings": MessageLookupByLibrary.simpleMessage(
      "Ouvrir les Réglages Système",
    ),
    "autoMutePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Accès au calendrier refusé. À activer dans Réglages Système > Confidentialité et sécurité > Calendriers.",
    ),
    "lamperoie": MessageLookupByLibrary.simpleMessage("Lampéroie"),
    "launchAtLoginDescription": MessageLookupByLibrary.simpleMessage(
      "Anchwatt apparaît dans la barre des menus dès l\'ouverture de session, fenêtre masquée. Clique sur l\'icône pour la rouvrir.",
    ),
    "launchAtLoginError": MessageLookupByLibrary.simpleMessage(
      "Raté, macOS a dit non",
    ),
    "launchAtLoginLabel": MessageLookupByLibrary.simpleMessage(
      "Démarrer à l\'ouverture de session",
    ),
    "notificationDndActivatedBody": m4,
    "notificationDndActivatedTitle": MessageLookupByLibrary.simpleMessage(
      "Mode silencieux activé",
    ),
    "notificationDndDeactivatedBody": m5,
    "notificationDndDeactivatedTitle": MessageLookupByLibrary.simpleMessage(
      "Mode silencieux désactivé",
    ),
    "notificationLevelUpBody": m6,
    "notificationLevelUpTitle": MessageLookupByLibrary.simpleMessage(
      "Anchwatt monte en grade !",
    ),
    "notificationsDescription": MessageLookupByLibrary.simpleMessage(
      "macOS t\'envoie une notif quand Anchwatt évolue ou quand le mode silencieux s\'allume/s\'éteint tout seul.",
    ),
    "notificationsLabel": MessageLookupByLibrary.simpleMessage("Notifications"),
    "notificationsPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Notifications refusées. À activer dans Réglages Système > Notifications > Anchwatt.",
    ),
    "ohmassacre": MessageLookupByLibrary.simpleMessage("Ohmassacre"),
    "optionsAppVersion": m7,
    "optionsButtonTooltip": MessageLookupByLibrary.simpleMessage(
      "Bidouiller Anchwatt",
    ),
    "optionsCloseTooltip": MessageLookupByLibrary.simpleMessage("Fermer"),
    "optionsGithubButton": MessageLookupByLibrary.simpleMessage(
      "Fouiner sur GitHub",
    ),
    "optionsGithubLabel": MessageLookupByLibrary.simpleMessage("Coulisses"),
    "optionsModeDescriptionCorporate": MessageLookupByLibrary.simpleMessage(
      "Sons sages pour quand le boss traîne par là.",
    ),
    "optionsModeDescriptionFriday": MessageLookupByLibrary.simpleMessage(
      "À fond la caisse, c\'est presque le week-end.",
    ),
    "optionsModeLabel": MessageLookupByLibrary.simpleMessage("Ambiance"),
    "optionsUpdatesAvailable": m8,
    "optionsUpdatesCheckButton": MessageLookupByLibrary.simpleMessage(
      "Chercher du neuf",
    ),
    "optionsUpdatesDownload": MessageLookupByLibrary.simpleMessage("Choper"),
    "optionsUpdatesError": MessageLookupByLibrary.simpleMessage(
      "Raté, GitHub fait la sourde oreille",
    ),
    "optionsUpdatesLabel": MessageLookupByLibrary.simpleMessage("Nouveautés"),
    "optionsUpdatesUpToDate": MessageLookupByLibrary.simpleMessage(
      "Tout est à jour, bravo !",
    ),
    "silentModeDescription": MessageLookupByLibrary.simpleMessage(
      "Coupe le sifflet à Anchwatt quand t\'es en réunion. Aucun son, aucun XP gagné non plus.",
    ),
    "silentModeLabel": MessageLookupByLibrary.simpleMessage("Ne pas déranger"),
    "silentModeTooltipDisabled": MessageLookupByLibrary.simpleMessage(
      "Chut, on bosse",
    ),
    "silentModeTooltipEnabled": MessageLookupByLibrary.simpleMessage(
      "La récré reprend",
    ),
    "soundModeCorporate": MessageLookupByLibrary.simpleMessage("Corporate"),
    "soundModeFriday": MessageLookupByLibrary.simpleMessage("Friday"),
    "soundModeSwitchToCorporate": MessageLookupByLibrary.simpleMessage(
      "Hop, Corporate",
    ),
    "soundModeSwitchToFriday": MessageLookupByLibrary.simpleMessage(
      "Hop, Friday",
    ),
    "systemVolumeTooltip": m9,
    "systemVolumeTooltipMuted": MessageLookupByLibrary.simpleMessage(
      "Silence radio",
    ),
  };
}
