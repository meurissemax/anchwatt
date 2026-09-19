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

  static String m3(level) =>
      "Mode Hardcore reverrouillé jusqu\'au niveau ${level}";

  static String m4(numeral) => "Cap sur le cycle ${numeral} ?";

  static String m5(numeral) => "CYCLE ${numeral}";

  static String m6(hours, minutes) => "${hours}h ${minutes}min";

  static String m7(minutes, seconds) => "${minutes}min ${seconds}s";

  static String m8(count) => "${count} nouveaux badges débloqués";

  static String m9(eventTitle, time) =>
      "${eventTitle} commence bientôt. Anchwatt se tait jusqu\'à ${time}.";

  static String m10(eventTitle) =>
      "${eventTitle} est terminé. Anchwatt reprend du service.";

  static String m11(from, to) => "${from} évolue en ${to}.";

  static String m12(from, level, to) =>
      "Niveau ${level} atteint. ${from} évolue en ${to}.";

  static String m13(name) => "${name} a gagné un niveau.";

  static String m14(level) => "Niveau ${level} atteint";

  static String m15(version) => "v${version}";

  static String m16(level) => "Débloqué au niveau ${level}.";

  static String m17(version) =>
      "Une nouvelle version a pointé son nez : ${version}";

  static String m18(mode) => "Ambiance : ${mode}";

  static String m19(level) => "Niveau ${level}. Tout ça pour ça.";

  static String m20(level) => "Niveau ${level} et toujours pas de promotion.";

  static String m21(level) =>
      "Niveau ${level}, et pourtant personne n\'a rien demandé.";

  static String m22(corporate, friday, hardcore) =>
      "dont ${corporate} en corporate, ${friday} en friday, ${hardcore} en hardcore";

  static String m23(percent) => "Haut-parleurs du Mac : ${percent} %";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "achievementChromaticDescription": MessageLookupByLibrary.simpleMessage(
      "Un premier Anchwatt chromatique croisé. Statistiquement, tu as eu de la chance.",
    ),
    "achievementChromaticLabel": MessageLookupByLibrary.simpleMessage(
      "Chromatique",
    ),
    "achievementCompulsivePetterDescription":
        MessageLookupByLibrary.simpleMessage(
          "500 papouilles distribuées. Il n\'a rien demandé.",
        ),
    "achievementCompulsivePetterLabel": MessageLookupByLibrary.simpleMessage(
      "Papouilleur compulsif",
    ),
    "achievementEndOfLineDescription": MessageLookupByLibrary.simpleMessage(
      "Niveau 100 atteint. Il n\'y a plus rien après, désolé.",
    ),
    "achievementEndOfLineLabel": MessageLookupByLibrary.simpleMessage(
      "Fin de ligne",
    ),
    "achievementFirstSparkDescription": MessageLookupByLibrary.simpleMessage(
      "Le tout premier événement système encaissé. Il fallait bien commencer.",
    ),
    "achievementFirstSparkLabel": MessageLookupByLibrary.simpleMessage(
      "Première étincelle",
    ),
    "achievementWelcomeToHellDescription": MessageLookupByLibrary.simpleMessage(
      "Niveau 50 atteint, mode Hardcore débloqué. Courage.",
    ),
    "achievementWelcomeToHellLabel": MessageLookupByLibrary.simpleMessage(
      "Bienvenue en enfer",
    ),
    "achievementWorkhorseDescription": MessageLookupByLibrary.simpleMessage(
      "1 000 événements système encaissés. Le repos attendra.",
    ),
    "achievementWorkhorseLabel": MessageLookupByLibrary.simpleMessage(
      "Bourreau de travail",
    ),
    "anchwatt": MessageLookupByLibrary.simpleMessage("Anchwatt"),
    "anchwattDebugAddCycle": MessageLookupByLibrary.simpleMessage("Cycle +1"),
    "anchwattDebugAddXp": MessageLookupByLibrary.simpleMessage("Ajouter XP"),
    "anchwattDebugForceShiny": MessageLookupByLibrary.simpleMessage("Shiny"),
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
    "cycleButton": MessageLookupByLibrary.simpleMessage("Effectuer un cycle"),
    "cycleDialogCancel": MessageLookupByLibrary.simpleMessage("Plus tard"),
    "cycleDialogConfirm": MessageLookupByLibrary.simpleMessage(
      "Lancer le cycle",
    ),
    "cycleDialogIntro": MessageLookupByLibrary.simpleMessage(
      "Anchwatt repart à neuf. Ce qui redémarre :",
    ),
    "cycleDialogIrreversible": MessageLookupByLibrary.simpleMessage(
      "Pas de marche arrière possible.",
    ),
    "cycleDialogKept": MessageLookupByLibrary.simpleMessage(
      "Tes stats, ton XP amassé et tes hauts faits restent acquis.",
    ),
    "cycleDialogLossForm": MessageLookupByLibrary.simpleMessage(
      "Retour à la forme Anchwatt de base",
    ),
    "cycleDialogLossHardcore": m3,
    "cycleDialogLossLevel": MessageLookupByLibrary.simpleMessage(
      "Retour au niveau 1",
    ),
    "cycleDialogTitle": m4,
    "cyclePlaque": m5,
    "cycleTierCopper": MessageLookupByLibrary.simpleMessage("Cuivre"),
    "cycleTierElectricBlue": MessageLookupByLibrary.simpleMessage(
      "Bleu électrique",
    ),
    "cycleTierPlasmaWhite": MessageLookupByLibrary.simpleMessage(
      "Blanc plasma",
    ),
    "cycleTierSteel": MessageLookupByLibrary.simpleMessage("Acier"),
    "cycleTierViolet": MessageLookupByLibrary.simpleMessage("Violet"),
    "durationHoursMinutes": m6,
    "durationMinutesSeconds": m7,
    "eventTypeChargerToggle": MessageLookupByLibrary.simpleMessage(
      "Coup de jus",
    ),
    "eventTypeExternalDisplayToggle": MessageLookupByLibrary.simpleMessage(
      "Écran en renfort",
    ),
    "eventTypeHeadphonesToggle": MessageLookupByLibrary.simpleMessage(
      "Casque vissé",
    ),
    "eventTypePet": MessageLookupByLibrary.simpleMessage("Papouille"),
    "eventTypeUsbToggle": MessageLookupByLibrary.simpleMessage("Branchage USB"),
    "evolutionFlavorAnchwatt": MessageLookupByLibrary.simpleMessage(
      "Petit mais déjà sous tension.",
    ),
    "evolutionFlavorLamperoie": MessageLookupByLibrary.simpleMessage(
      "Ça commence à sentir le grillé.",
    ),
    "evolutionFlavorOhmassacre": MessageLookupByLibrary.simpleMessage(
      "Niveau boss final, planque-toi.",
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
    "notificationAchievementUnlockedTitle":
        MessageLookupByLibrary.simpleMessage("Nouveau badge débloqué"),
    "notificationAchievementsUnlockedTitle": m8,
    "notificationCalendarEventFallbackName":
        MessageLookupByLibrary.simpleMessage("un événement"),
    "notificationDndActivatedBody": m9,
    "notificationDndActivatedTitle": MessageLookupByLibrary.simpleMessage(
      "Mode Ne pas déranger activé",
    ),
    "notificationDndDeactivatedBody": m10,
    "notificationDndDeactivatedTitle": MessageLookupByLibrary.simpleMessage(
      "Mode Ne pas déranger désactivé",
    ),
    "notificationEvolutionBody": m11,
    "notificationEvolutionTitle": MessageLookupByLibrary.simpleMessage(
      "Évolution !",
    ),
    "notificationHardcoreUnlockedBody": MessageLookupByLibrary.simpleMessage(
      "Anchwatt a débloqué le mode Hardcore. Il aurait préféré éviter.",
    ),
    "notificationHardcoreUnlockedTitle": MessageLookupByLibrary.simpleMessage(
      "Mode Hardcore débloqué",
    ),
    "notificationLevelUpAndEvolutionBody": m12,
    "notificationLevelUpAndEvolutionTitle":
        MessageLookupByLibrary.simpleMessage("Évolution !"),
    "notificationLevelUpBody": m13,
    "notificationLevelUpTitle": m14,
    "notificationShinyBody": MessageLookupByLibrary.simpleMessage(
      "La chance. Il t\'est apparu dans une teinte qu\'on ne voit presque jamais.",
    ),
    "notificationShinyTitle": MessageLookupByLibrary.simpleMessage(
      "Un Anchwatt chromatique !",
    ),
    "notificationsDescription": MessageLookupByLibrary.simpleMessage(
      "macOS t\'envoie une notif quand Anchwatt monte de niveau ou évolue, et quand le mode silencieux s\'allume/s\'éteint tout seul.",
    ),
    "notificationsLabel": MessageLookupByLibrary.simpleMessage("Notifications"),
    "notificationsPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Notifications refusées. À activer dans Réglages Système > Notifications > Anchwatt.",
    ),
    "ohmassacre": MessageLookupByLibrary.simpleMessage("Ohmassacre"),
    "optionsAppVersion": m15,
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
    "optionsModeDescriptionHardcore": MessageLookupByLibrary.simpleMessage(
      "Sans filtre, sans pitié. Anchwatt décline toute responsabilité.",
    ),
    "optionsModeHardcoreLockedTooltip": m16,
    "optionsModeLabel": MessageLookupByLibrary.simpleMessage("Ambiance"),
    "optionsUpdatesAvailable": m17,
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
    "soundModeHardcore": MessageLookupByLibrary.simpleMessage("Hardcore"),
    "soundModeTooltip": m18,
    "statsAchievementsTitle": MessageLookupByLibrary.simpleMessage(
      "Hauts faits",
    ),
    "statsButtonTooltip": MessageLookupByLibrary.simpleMessage(
      "Ton tableau de chasse",
    ),
    "statsCardCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Télécharger Anchwatt",
    ),
    "statsCardShareButton": MessageLookupByLibrary.simpleMessage(
      "Partager la carte",
    ),
    "statsCardShareCopied": MessageLookupByLibrary.simpleMessage(
      "Carte copiée !",
    ),
    "statsCardShareError": MessageLookupByLibrary.simpleMessage(
      "Raté, la carte n\'est pas passée",
    ),
    "statsCardTaglineFirst": m19,
    "statsCardTaglineSecond": m20,
    "statsCardTaglineThird": m21,
    "statsFavoriteEventDescription": MessageLookupByLibrary.simpleMessage(
      "L\'événement qui le titille le plus souvent",
    ),
    "statsFavoriteEventEmpty": MessageLookupByLibrary.simpleMessage(
      "Rien encore, tout roupille",
    ),
    "statsFavoriteEventLabel": MessageLookupByLibrary.simpleMessage(
      "Péché mignon",
    ),
    "statsLevelLabel": MessageLookupByLibrary.simpleMessage("Niveau"),
    "statsLifetimeXpLabel": MessageLookupByLibrary.simpleMessage("XP amassé"),
    "statsMemberSinceLabel": MessageLookupByLibrary.simpleMessage("Adopté le"),
    "statsPetsDescription": MessageLookupByLibrary.simpleMessage(
      "Toutes les papouilles que tu lui as offertes",
    ),
    "statsPetsLabel": MessageLookupByLibrary.simpleMessage("Papouilles"),
    "statsShinyDescription": MessageLookupByLibrary.simpleMessage(
      "Les fois où il t\'est apparu tout scintillant",
    ),
    "statsShinyLabel": MessageLookupByLibrary.simpleMessage("Chromatiques"),
    "statsSoundDurationDescription": MessageLookupByLibrary.simpleMessage(
      "Tout ce temps passé à brailler",
    ),
    "statsSoundDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Temps de bruit",
    ),
    "statsSoundsPlayedLabel": MessageLookupByLibrary.simpleMessage(
      "Sons lâchés",
    ),
    "statsSoundsSplit": m22,
    "statsWakeupsDescription": MessageLookupByLibrary.simpleMessage(
      "Un bond au plafond par événement",
    ),
    "statsWakeupsLabel": MessageLookupByLibrary.simpleMessage("Sursauts"),
    "systemVolumeTooltip": m23,
    "systemVolumeTooltipMuted": MessageLookupByLibrary.simpleMessage(
      "Silence radio — haut-parleurs du Mac coupés",
    ),
  };
}
