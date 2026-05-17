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

  static String m3(version) => "v${version}";

  static String m4(version) =>
      "Une nouvelle version a pointé son nez : ${version}";

  static String m5(percent) => "Volume : ${percent} %";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "anchwatt": MessageLookupByLibrary.simpleMessage("Anchwatt"),
    "anchwattDebugAddXp": MessageLookupByLibrary.simpleMessage("Tricher : +XP"),
    "anchwattEvolutionLevel": m0,
    "anchwattXpCounter": m1,
    "anchwattXpGain": m2,
    "lamperoie": MessageLookupByLibrary.simpleMessage("Lampéroie"),
    "ohmassacre": MessageLookupByLibrary.simpleMessage("Ohmassacre"),
    "optionsAppVersion": m3,
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
    "optionsUpdatesAvailable": m4,
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
    "soundModeCorporate": MessageLookupByLibrary.simpleMessage("Corporate"),
    "soundModeFriday": MessageLookupByLibrary.simpleMessage("Friday"),
    "soundModeSwitchToCorporate": MessageLookupByLibrary.simpleMessage(
      "Hop, en mode Corporate",
    ),
    "soundModeSwitchToFriday": MessageLookupByLibrary.simpleMessage(
      "Hop, en mode Friday",
    ),
    "systemVolumeTooltip": m5,
    "systemVolumeTooltipMuted": MessageLookupByLibrary.simpleMessage(
      "Silence radio",
    ),
  };
}
