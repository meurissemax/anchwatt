// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class L10n {
  L10n();

  static L10n? _current;

  static L10n get current {
    assert(
      _current != null,
      'No instance of L10n was loaded. Try to initialize the L10n delegate before accessing L10n.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<L10n> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = L10n();
      L10n._current = instance;

      return instance;
    });
  }

  static L10n of(BuildContext context) {
    final instance = L10n.maybeOf(context);
    assert(
      instance != null,
      'No instance of L10n present in the widget tree. Did you add L10n.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static L10n? maybeOf(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  /// `Un premier Anchwatt chromatique croisé. Statistiquement, tu as eu de la chance.`
  String get achievementChromaticDescription {
    return Intl.message(
      'Un premier Anchwatt chromatique croisé. Statistiquement, tu as eu de la chance.',
      name: 'achievementChromaticDescription',
      desc: '',
      args: [],
    );
  }

  /// `Chromatique`
  String get achievementChromaticLabel {
    return Intl.message(
      'Chromatique',
      name: 'achievementChromaticLabel',
      desc: '',
      args: [],
    );
  }

  /// `500 papouilles distribuées. Il n'a rien demandé.`
  String get achievementCompulsivePetterDescription {
    return Intl.message(
      '500 papouilles distribuées. Il n\'a rien demandé.',
      name: 'achievementCompulsivePetterDescription',
      desc: '',
      args: [],
    );
  }

  /// `Papouilleur compulsif`
  String get achievementCompulsivePetterLabel {
    return Intl.message(
      'Papouilleur compulsif',
      name: 'achievementCompulsivePetterLabel',
      desc: '',
      args: [],
    );
  }

  /// `Niveau 100 atteint. Il n'y a plus rien après, désolé.`
  String get achievementEndOfLineDescription {
    return Intl.message(
      'Niveau 100 atteint. Il n\'y a plus rien après, désolé.',
      name: 'achievementEndOfLineDescription',
      desc: '',
      args: [],
    );
  }

  /// `Fin de ligne`
  String get achievementEndOfLineLabel {
    return Intl.message(
      'Fin de ligne',
      name: 'achievementEndOfLineLabel',
      desc: '',
      args: [],
    );
  }

  /// `Le tout premier événement système encaissé. Il fallait bien commencer.`
  String get achievementFirstSparkDescription {
    return Intl.message(
      'Le tout premier événement système encaissé. Il fallait bien commencer.',
      name: 'achievementFirstSparkDescription',
      desc: '',
      args: [],
    );
  }

  /// `Première étincelle`
  String get achievementFirstSparkLabel {
    return Intl.message(
      'Première étincelle',
      name: 'achievementFirstSparkLabel',
      desc: '',
      args: [],
    );
  }

  /// `Niveau 50 atteint, mode Hardcore débloqué. Courage.`
  String get achievementWelcomeToHellDescription {
    return Intl.message(
      'Niveau 50 atteint, mode Hardcore débloqué. Courage.',
      name: 'achievementWelcomeToHellDescription',
      desc: '',
      args: [],
    );
  }

  /// `Bienvenue en enfer`
  String get achievementWelcomeToHellLabel {
    return Intl.message(
      'Bienvenue en enfer',
      name: 'achievementWelcomeToHellLabel',
      desc: '',
      args: [],
    );
  }

  /// `1 000 événements système encaissés. Le repos attendra.`
  String get achievementWorkhorseDescription {
    return Intl.message(
      '1 000 événements système encaissés. Le repos attendra.',
      name: 'achievementWorkhorseDescription',
      desc: '',
      args: [],
    );
  }

  /// `Bourreau de travail`
  String get achievementWorkhorseLabel {
    return Intl.message(
      'Bourreau de travail',
      name: 'achievementWorkhorseLabel',
      desc: '',
      args: [],
    );
  }

  /// `Anchwatt`
  String get anchwatt {
    return Intl.message('Anchwatt', name: 'anchwatt', desc: '', args: []);
  }

  /// `Ajouter XP`
  String get anchwattDebugAddXp {
    return Intl.message(
      'Ajouter XP',
      name: 'anchwattDebugAddXp',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get anchwattDebugResetStats {
    return Intl.message(
      'Reset',
      name: 'anchwattDebugResetStats',
      desc: '',
      args: [],
    );
  }

  /// `Simuler`
  String get anchwattDebugSimulateEvent {
    return Intl.message(
      'Simuler',
      name: 'anchwattDebugSimulateEvent',
      desc: '',
      args: [],
    );
  }

  /// `Shiny`
  String get anchwattDebugToggleShiny {
    return Intl.message(
      'Shiny',
      name: 'anchwattDebugToggleShiny',
      desc: '',
      args: [],
    );
  }

  /// `{current} / {total}`
  String anchwattXpCounter(String current, String total) {
    return Intl.message(
      '$current / $total',
      name: 'anchwattXpCounter',
      desc: '',
      args: [current, total],
    );
  }

  /// `+{xp}xp`
  String anchwattXpGain(String xp) {
    return Intl.message(
      '+${xp}xp',
      name: 'anchwattXpGain',
      desc: '',
      args: [xp],
    );
  }

  /// `Activé auto : {eventTitle} jusqu'à {time}`
  String autoMuteActiveReason(String eventTitle, String time) {
    return Intl.message(
      'Activé auto : $eventTitle jusqu\'à $time',
      name: 'autoMuteActiveReason',
      desc: '',
      args: [eventTitle, time],
    );
  }

  /// `Branche ton calendrier pour couper Anchwatt pile pendant les réunions.`
  String get autoMuteDescription {
    return Intl.message(
      'Branche ton calendrier pour couper Anchwatt pile pendant les réunions.',
      name: 'autoMuteDescription',
      desc: '',
      args: [],
    );
  }

  /// `Silence pendant les réunions`
  String get autoMuteLabel {
    return Intl.message(
      'Silence pendant les réunions',
      name: 'autoMuteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Ouvrir les Réglages Système`
  String get autoMuteOpenSystemSettings {
    return Intl.message(
      'Ouvrir les Réglages Système',
      name: 'autoMuteOpenSystemSettings',
      desc: '',
      args: [],
    );
  }

  /// `Accès au calendrier refusé. À activer dans Réglages Système > Confidentialité et sécurité > Calendriers.`
  String get autoMutePermissionDenied {
    return Intl.message(
      'Accès au calendrier refusé. À activer dans Réglages Système > Confidentialité et sécurité > Calendriers.',
      name: 'autoMutePermissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Coup de jus`
  String get eventTypeChargerToggle {
    return Intl.message(
      'Coup de jus',
      name: 'eventTypeChargerToggle',
      desc: '',
      args: [],
    );
  }

  /// `Écran en renfort`
  String get eventTypeExternalDisplayToggle {
    return Intl.message(
      'Écran en renfort',
      name: 'eventTypeExternalDisplayToggle',
      desc: '',
      args: [],
    );
  }

  /// `Casque vissé`
  String get eventTypeHeadphonesToggle {
    return Intl.message(
      'Casque vissé',
      name: 'eventTypeHeadphonesToggle',
      desc: '',
      args: [],
    );
  }

  /// `Papouille`
  String get eventTypePet {
    return Intl.message('Papouille', name: 'eventTypePet', desc: '', args: []);
  }

  /// `Branchage USB`
  String get eventTypeUsbToggle {
    return Intl.message(
      'Branchage USB',
      name: 'eventTypeUsbToggle',
      desc: '',
      args: [],
    );
  }

  /// `Petit mais déjà sous tension.`
  String get evolutionFlavorAnchwatt {
    return Intl.message(
      'Petit mais déjà sous tension.',
      name: 'evolutionFlavorAnchwatt',
      desc: '',
      args: [],
    );
  }

  /// `Ça commence à sentir le grillé.`
  String get evolutionFlavorLamperoie {
    return Intl.message(
      'Ça commence à sentir le grillé.',
      name: 'evolutionFlavorLamperoie',
      desc: '',
      args: [],
    );
  }

  /// `Niveau boss final, planque-toi.`
  String get evolutionFlavorOhmassacre {
    return Intl.message(
      'Niveau boss final, planque-toi.',
      name: 'evolutionFlavorOhmassacre',
      desc: '',
      args: [],
    );
  }

  /// `Lampéroie`
  String get lamperoie {
    return Intl.message('Lampéroie', name: 'lamperoie', desc: '', args: []);
  }

  /// `Anchwatt apparaît dans la barre des menus dès l'ouverture de session, fenêtre masquée. Clique sur l'icône pour la rouvrir.`
  String get launchAtLoginDescription {
    return Intl.message(
      'Anchwatt apparaît dans la barre des menus dès l\'ouverture de session, fenêtre masquée. Clique sur l\'icône pour la rouvrir.',
      name: 'launchAtLoginDescription',
      desc: '',
      args: [],
    );
  }

  /// `Raté, macOS a dit non`
  String get launchAtLoginError {
    return Intl.message(
      'Raté, macOS a dit non',
      name: 'launchAtLoginError',
      desc: '',
      args: [],
    );
  }

  /// `Démarrer à l'ouverture de session`
  String get launchAtLoginLabel {
    return Intl.message(
      'Démarrer à l\'ouverture de session',
      name: 'launchAtLoginLabel',
      desc: '',
      args: [],
    );
  }

  /// `{count} nouveaux badges débloqués`
  String notificationAchievementsUnlockedTitle(int count) {
    return Intl.message(
      '$count nouveaux badges débloqués',
      name: 'notificationAchievementsUnlockedTitle',
      desc: '',
      args: [count],
    );
  }

  /// `Nouveau badge débloqué`
  String get notificationAchievementUnlockedTitle {
    return Intl.message(
      'Nouveau badge débloqué',
      name: 'notificationAchievementUnlockedTitle',
      desc: '',
      args: [],
    );
  }

  /// `un événement`
  String get notificationCalendarEventFallbackName {
    return Intl.message(
      'un événement',
      name: 'notificationCalendarEventFallbackName',
      desc: '',
      args: [],
    );
  }

  /// `{eventTitle} commence bientôt. Anchwatt se tait jusqu'à {time}.`
  String notificationDndActivatedBody(String eventTitle, String time) {
    return Intl.message(
      '$eventTitle commence bientôt. Anchwatt se tait jusqu\'à $time.',
      name: 'notificationDndActivatedBody',
      desc: '',
      args: [eventTitle, time],
    );
  }

  /// `Mode Ne pas déranger activé`
  String get notificationDndActivatedTitle {
    return Intl.message(
      'Mode Ne pas déranger activé',
      name: 'notificationDndActivatedTitle',
      desc: '',
      args: [],
    );
  }

  /// `{eventTitle} est terminé. Anchwatt reprend du service.`
  String notificationDndDeactivatedBody(String eventTitle) {
    return Intl.message(
      '$eventTitle est terminé. Anchwatt reprend du service.',
      name: 'notificationDndDeactivatedBody',
      desc: '',
      args: [eventTitle],
    );
  }

  /// `Mode Ne pas déranger désactivé`
  String get notificationDndDeactivatedTitle {
    return Intl.message(
      'Mode Ne pas déranger désactivé',
      name: 'notificationDndDeactivatedTitle',
      desc: '',
      args: [],
    );
  }

  /// `{from} évolue en {to}.`
  String notificationEvolutionBody(String from, String to) {
    return Intl.message(
      '$from évolue en $to.',
      name: 'notificationEvolutionBody',
      desc: '',
      args: [from, to],
    );
  }

  /// `Évolution !`
  String get notificationEvolutionTitle {
    return Intl.message(
      'Évolution !',
      name: 'notificationEvolutionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Anchwatt a débloqué le mode Hardcore. Il aurait préféré éviter.`
  String get notificationHardcoreUnlockedBody {
    return Intl.message(
      'Anchwatt a débloqué le mode Hardcore. Il aurait préféré éviter.',
      name: 'notificationHardcoreUnlockedBody',
      desc: '',
      args: [],
    );
  }

  /// `Mode Hardcore débloqué`
  String get notificationHardcoreUnlockedTitle {
    return Intl.message(
      'Mode Hardcore débloqué',
      name: 'notificationHardcoreUnlockedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Niveau {level} atteint. {from} évolue en {to}.`
  String notificationLevelUpAndEvolutionBody(
    String from,
    String level,
    String to,
  ) {
    return Intl.message(
      'Niveau $level atteint. $from évolue en $to.',
      name: 'notificationLevelUpAndEvolutionBody',
      desc: '',
      args: [from, level, to],
    );
  }

  /// `Évolution !`
  String get notificationLevelUpAndEvolutionTitle {
    return Intl.message(
      'Évolution !',
      name: 'notificationLevelUpAndEvolutionTitle',
      desc: '',
      args: [],
    );
  }

  /// `{name} a gagné un niveau.`
  String notificationLevelUpBody(String name) {
    return Intl.message(
      '$name a gagné un niveau.',
      name: 'notificationLevelUpBody',
      desc: '',
      args: [name],
    );
  }

  /// `Niveau {level} atteint`
  String notificationLevelUpTitle(String level) {
    return Intl.message(
      'Niveau $level atteint',
      name: 'notificationLevelUpTitle',
      desc: '',
      args: [level],
    );
  }

  /// `macOS t'envoie une notif quand Anchwatt monte de niveau ou évolue, et quand le mode silencieux s'allume/s'éteint tout seul.`
  String get notificationsDescription {
    return Intl.message(
      'macOS t\'envoie une notif quand Anchwatt monte de niveau ou évolue, et quand le mode silencieux s\'allume/s\'éteint tout seul.',
      name: 'notificationsDescription',
      desc: '',
      args: [],
    );
  }

  /// `La chance. Il t'est apparu dans une teinte qu'on ne voit presque jamais.`
  String get notificationShinyBody {
    return Intl.message(
      'La chance. Il t\'est apparu dans une teinte qu\'on ne voit presque jamais.',
      name: 'notificationShinyBody',
      desc: '',
      args: [],
    );
  }

  /// `Un Anchwatt chromatique !`
  String get notificationShinyTitle {
    return Intl.message(
      'Un Anchwatt chromatique !',
      name: 'notificationShinyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notificationsLabel {
    return Intl.message(
      'Notifications',
      name: 'notificationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Notifications refusées. À activer dans Réglages Système > Notifications > Anchwatt.`
  String get notificationsPermissionDenied {
    return Intl.message(
      'Notifications refusées. À activer dans Réglages Système > Notifications > Anchwatt.',
      name: 'notificationsPermissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Ohmassacre`
  String get ohmassacre {
    return Intl.message('Ohmassacre', name: 'ohmassacre', desc: '', args: []);
  }

  /// `v{version}`
  String optionsAppVersion(String version) {
    return Intl.message(
      'v$version',
      name: 'optionsAppVersion',
      desc: '',
      args: [version],
    );
  }

  /// `Bidouiller Anchwatt`
  String get optionsButtonTooltip {
    return Intl.message(
      'Bidouiller Anchwatt',
      name: 'optionsButtonTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Fermer`
  String get optionsCloseTooltip {
    return Intl.message(
      'Fermer',
      name: 'optionsCloseTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Fouiner sur GitHub`
  String get optionsGithubButton {
    return Intl.message(
      'Fouiner sur GitHub',
      name: 'optionsGithubButton',
      desc: '',
      args: [],
    );
  }

  /// `Coulisses`
  String get optionsGithubLabel {
    return Intl.message(
      'Coulisses',
      name: 'optionsGithubLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sons sages pour quand le boss traîne par là.`
  String get optionsModeDescriptionCorporate {
    return Intl.message(
      'Sons sages pour quand le boss traîne par là.',
      name: 'optionsModeDescriptionCorporate',
      desc: '',
      args: [],
    );
  }

  /// `À fond la caisse, c'est presque le week-end.`
  String get optionsModeDescriptionFriday {
    return Intl.message(
      'À fond la caisse, c\'est presque le week-end.',
      name: 'optionsModeDescriptionFriday',
      desc: '',
      args: [],
    );
  }

  /// `Sans filtre, sans pitié. Anchwatt décline toute responsabilité.`
  String get optionsModeDescriptionHardcore {
    return Intl.message(
      'Sans filtre, sans pitié. Anchwatt décline toute responsabilité.',
      name: 'optionsModeDescriptionHardcore',
      desc: '',
      args: [],
    );
  }

  /// `Débloqué au niveau {level}.`
  String optionsModeHardcoreLockedTooltip(String level) {
    return Intl.message(
      'Débloqué au niveau $level.',
      name: 'optionsModeHardcoreLockedTooltip',
      desc: '',
      args: [level],
    );
  }

  /// `Ambiance`
  String get optionsModeLabel {
    return Intl.message(
      'Ambiance',
      name: 'optionsModeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Une nouvelle version a pointé son nez : {version}`
  String optionsUpdatesAvailable(String version) {
    return Intl.message(
      'Une nouvelle version a pointé son nez : $version',
      name: 'optionsUpdatesAvailable',
      desc: '',
      args: [version],
    );
  }

  /// `Chercher du neuf`
  String get optionsUpdatesCheckButton {
    return Intl.message(
      'Chercher du neuf',
      name: 'optionsUpdatesCheckButton',
      desc: '',
      args: [],
    );
  }

  /// `Choper`
  String get optionsUpdatesDownload {
    return Intl.message(
      'Choper',
      name: 'optionsUpdatesDownload',
      desc: '',
      args: [],
    );
  }

  /// `Raté, GitHub fait la sourde oreille`
  String get optionsUpdatesError {
    return Intl.message(
      'Raté, GitHub fait la sourde oreille',
      name: 'optionsUpdatesError',
      desc: '',
      args: [],
    );
  }

  /// `Nouveautés`
  String get optionsUpdatesLabel {
    return Intl.message(
      'Nouveautés',
      name: 'optionsUpdatesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Tout est à jour, bravo !`
  String get optionsUpdatesUpToDate {
    return Intl.message(
      'Tout est à jour, bravo !',
      name: 'optionsUpdatesUpToDate',
      desc: '',
      args: [],
    );
  }

  /// `Coupe le sifflet à Anchwatt quand t'es en réunion. Aucun son, aucun XP gagné non plus.`
  String get silentModeDescription {
    return Intl.message(
      'Coupe le sifflet à Anchwatt quand t\'es en réunion. Aucun son, aucun XP gagné non plus.',
      name: 'silentModeDescription',
      desc: '',
      args: [],
    );
  }

  /// `Ne pas déranger`
  String get silentModeLabel {
    return Intl.message(
      'Ne pas déranger',
      name: 'silentModeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Chut, on bosse`
  String get silentModeTooltipDisabled {
    return Intl.message(
      'Chut, on bosse',
      name: 'silentModeTooltipDisabled',
      desc: '',
      args: [],
    );
  }

  /// `La récré reprend`
  String get silentModeTooltipEnabled {
    return Intl.message(
      'La récré reprend',
      name: 'silentModeTooltipEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Corporate`
  String get soundModeCorporate {
    return Intl.message(
      'Corporate',
      name: 'soundModeCorporate',
      desc: '',
      args: [],
    );
  }

  /// `Friday`
  String get soundModeFriday {
    return Intl.message('Friday', name: 'soundModeFriday', desc: '', args: []);
  }

  /// `Hardcore`
  String get soundModeHardcore {
    return Intl.message(
      'Hardcore',
      name: 'soundModeHardcore',
      desc: '',
      args: [],
    );
  }

  /// `Ambiance : {mode}`
  String soundModeTooltip(String mode) {
    return Intl.message(
      'Ambiance : $mode',
      name: 'soundModeTooltip',
      desc: '',
      args: [mode],
    );
  }

  /// `Hauts faits`
  String get statsAchievementsTitle {
    return Intl.message(
      'Hauts faits',
      name: 'statsAchievementsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Ton tableau de chasse`
  String get statsButtonTooltip {
    return Intl.message(
      'Ton tableau de chasse',
      name: 'statsButtonTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Télécharger Anchwatt`
  String get statsCardCtaLabel {
    return Intl.message(
      'Télécharger Anchwatt',
      name: 'statsCardCtaLabel',
      desc: '',
      args: [],
    );
  }

  /// `Partager la carte`
  String get statsCardShareButton {
    return Intl.message(
      'Partager la carte',
      name: 'statsCardShareButton',
      desc: '',
      args: [],
    );
  }

  /// `Carte copiée !`
  String get statsCardShareCopied {
    return Intl.message(
      'Carte copiée !',
      name: 'statsCardShareCopied',
      desc: '',
      args: [],
    );
  }

  /// `Raté, la carte n'est pas passée`
  String get statsCardShareError {
    return Intl.message(
      'Raté, la carte n\'est pas passée',
      name: 'statsCardShareError',
      desc: '',
      args: [],
    );
  }

  /// `Niveau {level}. Tout ça pour ça.`
  String statsCardTaglineFirst(String level) {
    return Intl.message(
      'Niveau $level. Tout ça pour ça.',
      name: 'statsCardTaglineFirst',
      desc: '',
      args: [level],
    );
  }

  /// `Niveau {level} et toujours pas de promotion.`
  String statsCardTaglineSecond(String level) {
    return Intl.message(
      'Niveau $level et toujours pas de promotion.',
      name: 'statsCardTaglineSecond',
      desc: '',
      args: [level],
    );
  }

  /// `Niveau {level}, et pourtant personne n'a rien demandé.`
  String statsCardTaglineThird(String level) {
    return Intl.message(
      'Niveau $level, et pourtant personne n\'a rien demandé.',
      name: 'statsCardTaglineThird',
      desc: '',
      args: [level],
    );
  }

  /// `L'événement qui le titille le plus souvent`
  String get statsFavoriteEventDescription {
    return Intl.message(
      'L\'événement qui le titille le plus souvent',
      name: 'statsFavoriteEventDescription',
      desc: '',
      args: [],
    );
  }

  /// `Rien encore, tout roupille`
  String get statsFavoriteEventEmpty {
    return Intl.message(
      'Rien encore, tout roupille',
      name: 'statsFavoriteEventEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Péché mignon`
  String get statsFavoriteEventLabel {
    return Intl.message(
      'Péché mignon',
      name: 'statsFavoriteEventLabel',
      desc: '',
      args: [],
    );
  }

  /// `Niveau`
  String get statsLevelLabel {
    return Intl.message('Niveau', name: 'statsLevelLabel', desc: '', args: []);
  }

  /// `XP amassé`
  String get statsLifetimeXpLabel {
    return Intl.message(
      'XP amassé',
      name: 'statsLifetimeXpLabel',
      desc: '',
      args: [],
    );
  }

  /// `Adopté le`
  String get statsMemberSinceLabel {
    return Intl.message(
      'Adopté le',
      name: 'statsMemberSinceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Toutes les papouilles que tu lui as offertes`
  String get statsPetsDescription {
    return Intl.message(
      'Toutes les papouilles que tu lui as offertes',
      name: 'statsPetsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Papouilles`
  String get statsPetsLabel {
    return Intl.message(
      'Papouilles',
      name: 'statsPetsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Les fois où il t'est apparu tout scintillant`
  String get statsShinyDescription {
    return Intl.message(
      'Les fois où il t\'est apparu tout scintillant',
      name: 'statsShinyDescription',
      desc: '',
      args: [],
    );
  }

  /// `Chromatiques`
  String get statsShinyLabel {
    return Intl.message(
      'Chromatiques',
      name: 'statsShinyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sons lâchés`
  String get statsSoundsPlayedLabel {
    return Intl.message(
      'Sons lâchés',
      name: 'statsSoundsPlayedLabel',
      desc: '',
      args: [],
    );
  }

  /// `dont {corporate} en corporate, {friday} en friday, {hardcore} en hardcore`
  String statsSoundsSplit(String corporate, String friday, String hardcore) {
    return Intl.message(
      'dont $corporate en corporate, $friday en friday, $hardcore en hardcore',
      name: 'statsSoundsSplit',
      desc: '',
      args: [corporate, friday, hardcore],
    );
  }

  /// `Tableau de chasse`
  String get statsTitle {
    return Intl.message(
      'Tableau de chasse',
      name: 'statsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Un bond au plafond par événement`
  String get statsWakeupsDescription {
    return Intl.message(
      'Un bond au plafond par événement',
      name: 'statsWakeupsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Sursauts`
  String get statsWakeupsLabel {
    return Intl.message(
      'Sursauts',
      name: 'statsWakeupsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Volume : {percent} %`
  String systemVolumeTooltip(int percent) {
    return Intl.message(
      'Volume : $percent %',
      name: 'systemVolumeTooltip',
      desc: '',
      args: [percent],
    );
  }

  /// `Silence radio`
  String get systemVolumeTooltipMuted {
    return Intl.message(
      'Silence radio',
      name: 'systemVolumeTooltipMuted',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<L10n> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'fr')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<L10n> load(Locale locale) => L10n.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
