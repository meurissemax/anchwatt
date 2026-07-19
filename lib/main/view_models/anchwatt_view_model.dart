import 'dart:async';
import 'dart:math';

import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/calendar_auto_mute_service.dart';
import 'package:anchwatt/main/services/charger_event_service.dart';
import 'package:anchwatt/main/services/external_display_event_service.dart';
import 'package:anchwatt/main/services/headphones_event_service.dart';
import 'package:anchwatt/main/services/launch_at_login_service.dart';
import 'package:anchwatt/main/services/notification_service.dart';
import 'package:anchwatt/main/services/playback_volume_sampler.dart';
import 'package:anchwatt/main/services/silent_mode_service.dart';
import 'package:anchwatt/main/services/sound_service.dart';
import 'package:anchwatt/main/services/stats_service.dart';
import 'package:anchwatt/main/services/system_volume_service.dart';
import 'package:anchwatt/main/services/update_service.dart';
import 'package:anchwatt/main/services/usb_event_service.dart';
import 'package:anchwatt/main/services/window_state_service.dart';
import 'package:anchwatt/main/storages/anchwatt_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class AnchwattViewModel extends ChangeNotifier {
  /* Static variables */

  static final Random _petRandom = Random();

  /* Variables */

  final AnchwattStorage _storage = AnchwattStorage();
  final UsbEventService _usbEventService = UsbEventService();
  final ChargerEventService _chargerEventService = ChargerEventService();
  final ExternalDisplayEventService _externalDisplayEventService = ExternalDisplayEventService();
  final HeadphonesEventService _headphonesEventService = HeadphonesEventService();
  final LaunchAtLoginService _launchAtLoginService = LaunchAtLoginService();
  final SilentModeService _silentModeService = SilentModeService();
  late final CalendarAutoMuteService _calendarAutoMuteService = CalendarAutoMuteService(_silentModeService);
  final WindowStateService _windowStateService = WindowStateService();
  late final NotificationService _notificationService = NotificationService(
    isWindowHidden: _windowStateService.isWindowHidden,
    onNotificationTap: () => unawaited(_windowStateService.showWindow()),
  );
  final SoundService _soundService = SoundService();
  final UpdateService _updateService = UpdateService();
  final SystemVolumeService _systemVolumeService = SystemVolumeService();
  final StatsService _statsService = locator<StatsService>();

  StreamSubscription<void>? _usbSubscription;
  StreamSubscription<void>? _chargerSubscription;
  StreamSubscription<void>? _externalDisplaySubscription;
  StreamSubscription<void>? _headphonesSubscription;
  StreamSubscription<SystemVolumeState>? _systemVolumeSubscription;
  StreamSubscription<CalendarMuteTransition>? _calendarTransitionSubscription;
  // Fires refreshSystemPermissions() whenever the app returns to the foreground,
  // so a permission changed in System Settings applies without a restart.
  // Assigned at the end of _bootServices() (after the permission services'
  // init()) to avoid racing the boot-time reads.
  late final AppLifecycleListener _lifecycleListener;
  final StreamController<int> _xpGainController = StreamController<int>.broadcast();
  final ValueNotifier<bool> _hardcoreUnlockedNotifier = ValueNotifier<bool>(false);
  int _level = AnchwattSettings.levelMin;
  int _xp = 0;
  Future<void>? _pending;
  UpdateStatus _updateStatus = const UpdateUnknown();
  SystemVolumeState _systemVolumeState = SystemVolumeState.initial();
  DateTime? _lastPetCryAt;
  Duration _nextPetCryCooldown = Duration.zero;
  DateTime? _lastSystemEventAt;
  // RNG for the shiny roll. In-place like SoundService's random sound picker;
  // the odds themselves are unit-tested via AnchwattSettings.rollShiny.
  final Random _random = Random();
  // Runtime-only: the sprite is never shiny on launch and this is not persisted.
  bool _isShiny = false;

  /* Constructor */

  AnchwattViewModel() {
    _bootServices();
  }

  /* Getters */

  int get level => _level;
  int get xp => _xp;
  int get xpToNextLevel => AnchwattSettings.xpForLevel(_level);
  Evolution get evolution => Evolution.fromLevel(_level);
  double get progress => (_xp / xpToNextLevel).clamp(0, 1);
  bool get isMaxLevel => _level >= AnchwattSettings.levelMax;
  bool get isShiny => _isShiny;
  bool get isHardcoreUnlocked => _level >= AnchwattSettings.hardcoreUnlockLevel;
  UpdateStatus get updateStatus => _updateStatus;
  SystemVolumeState get systemVolumeState => _systemVolumeState;
  ValueNotifier<SoundMode> get soundModeNotifier => _soundService.modeNotifier;
  ValueNotifier<bool> get hardcoreUnlockedNotifier => _hardcoreUnlockedNotifier;
  ValueNotifier<bool> get silentModeNotifier => _silentModeService.enabledNotifier;
  ValueNotifier<bool> get launchAtLoginNotifier => _launchAtLoginService.enabledNotifier;
  ValueNotifier<bool> get autoMuteEnabledNotifier => _calendarAutoMuteService.enabledNotifier;
  ValueNotifier<BusyEvent?> get autoMuteActiveEventNotifier => _calendarAutoMuteService.activeEventNotifier;
  ValueNotifier<CalendarAutoMuteError?> get autoMuteErrorNotifier => _calendarAutoMuteService.errorNotifier;
  ValueNotifier<bool> get notificationsEnabledNotifier => _notificationService.enabledNotifier;
  ValueNotifier<NotificationServiceError?> get notificationsErrorNotifier => _notificationService.errorNotifier;
  Stream<int> get xpGainStream => _xpGainController.stream;

  /* Methods */

  // Cycles to the next mode, skipping Hardcore while it is locked so the pill
  // is a 2-state toggle below the unlock level and a 3-state cycle at or above
  // it. Reads [isHardcoreUnlocked] at tap time, so it flips live on level-up.
  Future<void> toggleSoundMode() {
    SoundMode next = _soundService.mode.next;
    if (next == SoundMode.hardcore && !isHardcoreUnlocked) {
      next = next.next;
    }

    return _soundService.setMode(next);
  }

  // Selects a mode directly (settings picker). Hardcore below its unlock level
  // is an inconsistent selection (stale prefs, or a locked pill somehow tapped)
  // — fall back to Corporate silently.
  Future<void> setSoundMode(SoundMode mode) {
    final SoundMode target = mode == SoundMode.hardcore && !isHardcoreUnlocked ? SoundMode.corporate : mode;

    return _soundService.setMode(target);
  }

  // The toggle reflects the combined DND state (manual OR calendar). When the
  // user turns it off while a calendar event is driving DND, opt out of that
  // event for the remainder of its duration; the manual flag is set to false
  // either way so a subsequent calendar transition can re-enable DND naturally.
  Future<void> toggleSilentMode() async {
    if (_silentModeService.isEnabled) {
      if (_silentModeService.calendarEnabled) {
        _calendarAutoMuteService.captureCurrentEventAsOverride();
      }
      await _silentModeService.setManualEnabled(false);
    } else {
      await _silentModeService.setManualEnabled(true);
    }
  }

  Future<void> setAutoMuteEnabled(bool value) => _calendarAutoMuteService.setEnabled(value);

  Future<void> openCalendarSystemSettings() => _calendarAutoMuteService.openSystemSettings();

  Future<void> setNotificationsEnabled(bool value) => _notificationService.setEnabled(value);

  Future<void> openNotificationsSystemSettings() => _notificationService.openSystemSettings();

  Future<void> refreshLaunchAtLogin() => _launchAtLoginService.refresh();

  // Re-reads every option backed by macOS system state (notification + calendar
  // permissions, login item) so a change made in System Settings while the app
  // was in the background is reflected on the next foreground. Wired to the
  // AppLifecycleListener; safe to call repeatedly.
  Future<void> refreshSystemPermissions() async {
    await _notificationService.refreshPermission();
    await _calendarAutoMuteService.refreshPermission();

    try {
      await refreshLaunchAtLogin();
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: LaunchAtLoginService refresh failed: $error');
    }
  }

  Future<void> setLaunchAtLogin(bool value) => _launchAtLoginService.setEnabled(value);

  Future<void> addXp(int amount) {
    final Future<void> next = (_pending ?? Future<void>.value()).then((_) => _process(amount));
    _pending = next;

    next.whenComplete(() {
      if (identical(_pending, next)) {
        _pending = null;
      }
    });

    return next;
  }

  Future<void> debugAddXp() => addXp(
    AnchwattSettings.xpForEvent(
      type: AnchwattEventType.usbToggle,
      level: _level,
      mode: _soundService.modeNotifier.value,
      systemVolume: 1,
    ),
  );

  Future<void> debugSimulateEvent() => _handleSystemEvent(AnchwattEventType.usbToggle);

  // Forces the shiny display state only (no stat, no notification) so the
  // recoloured sprite can be inspected without waiting on the roll.
  void debugToggleShiny() {
    _isShiny = !_isShiny;

    notifyListeners();
  }

  Future<void> debugResetStats() async {
    _level = AnchwattSettings.levelMin;
    _xp = 0;
    _hardcoreUnlockedNotifier.value = isHardcoreUnlocked;

    notifyListeners();

    await _storage.clear();
    await _statsService.reset();
  }

  void onPetTick() {
    // Gate before touching the cooldown so a flurry of pets under DND does
    // not silently push the next cry's cooldown forward.
    if (_silentModeService.isEnabled) {
      return;
    }

    final DateTime now = DateTime.now();

    if (_lastPetCryAt != null && now.difference(_lastPetCryAt!) < _nextPetCryCooldown) {
      return;
    }

    _lastPetCryAt = now;
    _nextPetCryCooldown = _rollPetCooldown(
      min: AnchwattSettings.petCryCooldownMinSeconds,
      max: AnchwattSettings.petCryCooldownMaxSeconds,
    );

    _statsService.recordPetInteraction();

    unawaited(_playPetCryAndGrantXp());
  }

  Future<void> _playPetCryAndGrantXp() async {
    final int level = _level;
    final SoundMode mode = _soundService.modeNotifier.value;
    final Evolution evo = evolution;
    final SystemVolumeState start = _systemVolumeState;
    final double initialVolume = start.muted ? 0.0 : start.volume;

    final PlaybackVolumeSampler sampler = PlaybackVolumeSampler(
      volumeStream: _systemVolumeService.events,
      initialVolume: initialVolume,
    );

    await _soundService.playCry(evo);
    final double meanVolume = sampler.stop();

    final int xp = AnchwattSettings.xpForEvent(
      type: AnchwattEventType.pet,
      level: level,
      mode: mode,
      systemVolume: meanVolume,
    );

    if (xp > 0) {
      await addXp(xp);
    }
  }

  Duration _rollPetCooldown({required int min, required int max}) =>
      Duration(milliseconds: min * 1000 + _petRandom.nextInt((max - min) * 1000 + 1));

  void _onSilentModeChanged() {
    if (_silentModeService.isEnabled) {
      unawaited(_soundService.stopAll());
    }
  }

  void _onCalendarTransition(CalendarMuteTransition transition) {
    switch (transition) {
      case CalendarMuteActivated(:final event):
        unawaited(_notificationService.showCalendarDndActivated(event.title, event.endTime));

      case CalendarMuteDeactivated(:final endedEvent):
        unawaited(_notificationService.showCalendarDndDeactivated(endedEvent.title));
    }
  }

  // DND silences level-up and evolution notifications (calendar DND notifs
  // bypass this — they must fire to tell the user why Anchwatt just went
  // quiet). Permission + foreground checks live inside NotificationService.
  Future<void> _maybeFireProgressionNotification({
    required int oldLevel,
    required int newLevel,
    required Evolution oldEvolution,
    required Evolution newEvolution,
  }) async {
    if (_silentModeService.isEnabled) {
      return;
    }

    // Reaching the Hardcore unlock level is a one-time milestone: fire its own
    // notification and skip the generic level-up for this crossing so a single
    // notification surfaces. The < / >= test catches a multi-level jump, and
    // levels only increase (bar the debug reset), so it fires exactly once.
    final bool unlockedHardcore =
        oldLevel < AnchwattSettings.hardcoreUnlockLevel && newLevel >= AnchwattSettings.hardcoreUnlockLevel;
    if (unlockedHardcore) {
      await _notificationService.showHardcoreUnlocked();

      return;
    }

    final bool leveledUp = newLevel > oldLevel;
    final bool evolved = newEvolution != oldEvolution;

    if (leveledUp && evolved) {
      await _notificationService.showLevelUpAndEvolution(newLevel, oldEvolution, newEvolution);
    } else if (evolved) {
      await _notificationService.showEvolution(oldEvolution, newEvolution);
    } else if (leveledUp) {
      await _notificationService.showLevelUp(newLevel, newEvolution);
    }
  }

  // Single coalescence point for every native system event (USB, charger,
  // external display, headphones). One physical action — e.g. plugging in a
  // USB-C dock — can fan out into several events in quick succession; we let
  // the first one in the window play a sound and grant XP, and absorb the
  // rest. Per-channel debounces (the 1500ms USB iPhone-handshake one) still
  // run upstream of this method.
  Future<void> _handleSystemEvent(AnchwattEventType type) async {
    // Gate before the coalesce-window update so a stream of events during
    // DND does not poison the window the moment DND turns off.
    if (_silentModeService.isEnabled) {
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? last = _lastSystemEventAt;
    if (last != null && now.difference(last) < AnchwattSettings.systemEventCoalesceWindow) {
      return;
    }
    _lastSystemEventAt = now;

    // Count the coalesced action exactly once, here on the existing debounced
    // path, regardless of whether it ends up muted or granting zero XP — so the
    // "réveils" total reflects every physical reaction.
    _statsService.recordSystemEvent(type);

    // Roll for a shiny on every confirmed (post-DND, post-coalesce) random-sound
    // event. The result both sets and clears the shiny state, so a non-shiny
    // event clears a previous shiny — the sprite stays shiny only until the next
    // such event. Runs before the zero-XP early return so a muted (but not DND)
    // event still re-rolls. The pet path never reaches this method.
    final bool shiny = AnchwattSettings.rollShiny(_random);
    if (shiny != _isShiny) {
      _isShiny = shiny;
      notifyListeners();
    }
    if (shiny) {
      _statsService.recordShinyEncounter();
      unawaited(_notificationService.showShiny());
    }

    // Snapshot level and mode at event time so a level-up or mode change
    // during playback does not retroactively shift the XP for this event.
    final int level = _level;
    final SoundMode mode = _soundService.modeNotifier.value;
    final SystemVolumeState startState = _systemVolumeState;
    final double initialVolume = startState.muted ? 0.0 : startState.volume;

    final PlaybackVolumeSampler sampler = PlaybackVolumeSampler(
      volumeStream: _systemVolumeService.events,
      initialVolume: initialVolume,
    );

    await _soundService.playRandom();
    final double meanVolume = sampler.stop();

    final int xp = AnchwattSettings.xpForEvent(
      type: type,
      level: level,
      mode: mode,
      systemVolume: meanVolume,
    );

    if (xp <= 0) {
      return;
    }

    await addXp(xp);
  }

  Future<void> _bootServices() async {
    await _storage.init();
    final ({int level, int xp}) initial = _storage.readProgression();
    _level = initial.level;
    _xp = initial.xp;
    _hardcoreUnlockedNotifier.value = isHardcoreUnlocked;
    notifyListeners();

    // Load stats before the event services start so no reaction can be missed,
    // and so the first launch after this update seeds the "member since" date.
    try {
      await _statsService.init();
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: StatsService init failed: $error');
    }

    try {
      await _silentModeService.init();
      _silentModeService.enabledNotifier.addListener(_onSilentModeChanged);
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: SilentModeService init failed: $error');
    }

    try {
      await _calendarAutoMuteService.init();
      _calendarTransitionSubscription = _calendarAutoMuteService.transitions.listen(_onCalendarTransition);
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: CalendarAutoMuteService init failed: $error');
    }

    try {
      await _notificationService.init();
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: NotificationService init failed: $error');
    }

    try {
      await _launchAtLoginService.refresh();
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: LaunchAtLoginService refresh failed: $error');
    }

    try {
      await _soundService.init();
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: SoundService init failed: $error');
    }

    // Defensive: a persisted Hardcore selection is invalid below the unlock
    // level (stale prefs from a bug or a rebalance) — fall back silently.
    if (_soundService.mode == SoundMode.hardcore && !isHardcoreUnlocked) {
      await _soundService.setMode(SoundMode.corporate);
    }

    try {
      await _usbEventService.start();
      _usbSubscription = _usbEventService.events.listen(
        (_) => _handleSystemEvent(AnchwattEventType.usbToggle),
      );
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: UsbEventService start failed: $error');
    }

    try {
      await _chargerEventService.start();
      _chargerSubscription = _chargerEventService.events.listen(
        (_) => _handleSystemEvent(AnchwattEventType.chargerToggle),
      );
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: ChargerEventService start failed: $error');
    }

    try {
      await _externalDisplayEventService.start();
      _externalDisplaySubscription = _externalDisplayEventService.events.listen(
        (_) => _handleSystemEvent(AnchwattEventType.externalDisplayToggle),
      );
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: ExternalDisplayEventService start failed: $error');
    }

    try {
      await _headphonesEventService.start();
      _headphonesSubscription = _headphonesEventService.events.listen(
        (_) => _handleSystemEvent(AnchwattEventType.headphonesToggle),
      );
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: HeadphonesEventService start failed: $error');
    }

    try {
      await _systemVolumeService.start();
      _systemVolumeSubscription = _systemVolumeService.events.listen((SystemVolumeState state) {
        if (state == _systemVolumeState) {
          return;
        }

        _systemVolumeState = state;
        notifyListeners();
      });
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: SystemVolumeService start failed: $error');
    }

    unawaited(
      _updateService.check().then((status) {
        _updateStatus = status;
        notifyListeners();
      }),
    );

    // All permission-bearing services have completed init() above, so the first
    // resume-driven refresh can't race their boot-time reads.
    _lifecycleListener = AppLifecycleListener(
      onResume: () => unawaited(refreshSystemPermissions()),
    );
  }

  Future<void> openLatestRelease() async {
    final UpdateStatus status = _updateStatus;
    if (status is! UpdateAvailable) {
      return;
    }

    await launchUrl(
      Uri.parse(status.releaseUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<UpdateStatus> forceCheckUpdates() async {
    final UpdateStatus status = await _updateService.check(force: true);
    _updateStatus = status;

    notifyListeners();

    return status;
  }

  Future<void> _process(int amount) async {
    // Accumulate granted XP from the single grant funnel (system events, pet,
    // debug), before the max-level guard so the lifetime total keeps climbing
    // even at cap. Self-contained: tracks the granted [amount], not _xp.
    _statsService.addLifetimeXp(amount);

    if (isMaxLevel) {
      return;
    }

    // Snapshot before the loop so a multi-level gain (e.g. after a balance
    // tweak that drops thresholds) collapses into a single notification for
    // the final state, instead of one per palier crossed.
    final int oldLevel = _level;
    final Evolution oldEvolution = Evolution.fromLevel(oldLevel);

    _xp += amount;
    _xpGainController.add(amount);

    // Resolve every crossed palier synchronously so _level/_xp are always the
    // authoritative, up-to-date state. The "fill up and roll over" pacing is a
    // presentation concern handled frame-by-frame in XpProgressBar — it must
    // never gate this model or the addXp pipeline (a stalled timer here once
    // froze leveling with the bar pinned full until the app was restarted).
    while (_xp >= AnchwattSettings.xpForLevel(_level) && _level < AnchwattSettings.levelMax) {
      _xp -= AnchwattSettings.xpForLevel(_level);
      _level += 1;
    }

    if (_level >= AnchwattSettings.levelMax) {
      _level = AnchwattSettings.levelMax;
      _xp = AnchwattSettings.xpForLevel(AnchwattSettings.levelMax);
    }

    _hardcoreUnlockedNotifier.value = isHardcoreUnlocked;

    notifyListeners();

    await _storage.writeProgression(level: _level, xp: _xp);

    unawaited(
      _maybeFireProgressionNotification(
        oldLevel: oldLevel,
        newLevel: _level,
        oldEvolution: oldEvolution,
        newEvolution: Evolution.fromLevel(_level),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _usbSubscription?.cancel();
    _usbEventService.stop();
    _chargerSubscription?.cancel();
    _chargerEventService.stop();
    _externalDisplaySubscription?.cancel();
    _externalDisplayEventService.stop();
    _headphonesSubscription?.cancel();
    _headphonesEventService.stop();
    _systemVolumeSubscription?.cancel();
    _systemVolumeService.stop();
    _calendarTransitionSubscription?.cancel();
    _silentModeService.enabledNotifier.removeListener(_onSilentModeChanged);
    _calendarAutoMuteService.dispose();
    _notificationService.dispose();
    _silentModeService.dispose();
    _launchAtLoginService.dispose();
    _soundService.dispose();
    _hardcoreUnlockedNotifier.dispose();
    _xpGainController.close();
    super.dispose();
  }
}
