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

  static String m0(current, total) => "${current} / ${total}";

  static String m1(xp) => "+${xp}xp";

  static String m2(eventTitle, time) =>
      "Activé auto : ${eventTitle} jusqu\'à ${time}";

  static String m3(eventTitle, time) =>
      "Anchwatt se tait pendant ${eventTitle} (jusqu\'à ${time}).";

  static String m4(eventTitle) =>
      "${eventTitle} est terminé. Anchwatt reprend du service.";

  static String m5(from, to) => "${from} évolue en ${to}.";

  static String m6(from, level, to) =>
      "Niveau ${level} atteint. ${from} évolue en ${to}.";

  static String m7(name) => "${name} a gagné un niveau.";

  static String m8(level) => "Niveau ${level} atteint";

  static String m9(version) => "v${version}";

  static String m10(version) =>
      "Une nouvelle version a pointé son nez : ${version}";

  static String m11(percent) => "Volume : ${percent} %";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "anchwatt": MessageLookupByLibrary.simpleMessage("Anchwatt"),
    "anchwattDebugAddXp": MessageLookupByLibrary.simpleMessage("Ajouter XP"),
    "anchwattDebugResetStats": MessageLookupByLibrary.simpleMessage("Reset"),
    "anchwattDebugSimulateEvent": MessageLookupByLibrary.simpleMessage(
      "Simuler",
    ),
    "anchwattXpCounter": m0,
    "anchwattXpGain": m1,
    "autoMuteActiveReason": m2,
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
    "notificationCalendarEventFallbackName":
        MessageLookupByLibrary.simpleMessage("un événement"),
    "notificationDndActivatedBody": m3,
    "notificationDndActivatedTitle": MessageLookupByLibrary.simpleMessage(
      "Mode Ne pas déranger activé",
    ),
    "notificationDndDeactivatedBody": m4,
    "notificationDndDeactivatedTitle": MessageLookupByLibrary.simpleMessage(
      "Mode Ne pas déranger désactivé",
    ),
    "notificationEvolutionBody": m5,
    "notificationEvolutionTitle": MessageLookupByLibrary.simpleMessage(
      "Évolution !",
    ),
    "notificationLevelUpAndEvolutionBody": m6,
    "notificationLevelUpAndEvolutionTitle":
        MessageLookupByLibrary.simpleMessage("Évolution !"),
    "notificationLevelUpBody": m7,
    "notificationLevelUpTitle": m8,
    "notificationsDescription": MessageLookupByLibrary.simpleMessage(
      "macOS t\'envoie une notif quand Anchwatt monte de niveau ou évolue, et quand le mode silencieux s\'allume/s\'éteint tout seul.",
    ),
    "notificationsLabel": MessageLookupByLibrary.simpleMessage("Notifications"),
    "notificationsPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Notifications refusées. À activer dans Réglages Système > Notifications > Anchwatt.",
    ),
    "ohmassacre": MessageLookupByLibrary.simpleMessage("Ohmassacre"),
    "optionsAppVersion": m9,
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
    "optionsUpdatesAvailable": m10,
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
    "systemVolumeTooltip": m11,
    "systemVolumeTooltipMuted": MessageLookupByLibrary.simpleMessage(
      "Silence radio",
    ),
  };
}
