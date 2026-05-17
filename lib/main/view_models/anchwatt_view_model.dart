import 'dart:async';
import 'dart:math';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/charger_event_service.dart';
import 'package:anchwatt/main/services/external_display_event_service.dart';
import 'package:anchwatt/main/services/headphones_event_service.dart';
import 'package:anchwatt/main/services/playback_volume_sampler.dart';
import 'package:anchwatt/main/services/silent_mode_service.dart';
import 'package:anchwatt/main/services/sound_service.dart';
import 'package:anchwatt/main/services/system_volume_service.dart';
import 'package:anchwatt/main/services/update_service.dart';
import 'package:anchwatt/main/services/usb_event_service.dart';
import 'package:anchwatt/main/storages/anchwatt_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class AnchwattViewModel extends ChangeNotifier {
  /* Static variables */

  static const Duration defaultLevelUpDwell = Duration(milliseconds: 500);
  static final Random _petRandom = Random();

  /* Variables */

  final Duration _levelUpDwell;
  final AnchwattStorage _storage = AnchwattStorage();
  final UsbEventService _usbEventService = UsbEventService();
  final ChargerEventService _chargerEventService = ChargerEventService();
  final ExternalDisplayEventService _externalDisplayEventService = ExternalDisplayEventService();
  final HeadphonesEventService _headphonesEventService = HeadphonesEventService();
  final SilentModeService _silentModeService = SilentModeService();
  final SoundService _soundService = SoundService();
  final UpdateService _updateService = UpdateService();
  final SystemVolumeService _systemVolumeService = SystemVolumeService();

  StreamSubscription<void>? _usbSubscription;
  StreamSubscription<void>? _chargerSubscription;
  StreamSubscription<void>? _externalDisplaySubscription;
  StreamSubscription<void>? _headphonesSubscription;
  StreamSubscription<SystemVolumeState>? _systemVolumeSubscription;
  final StreamController<int> _xpGainController = StreamController<int>.broadcast();
  int _level = AnchwattSettings.levelMin;
  int _xp = 0;
  Future<void>? _pending;
  UpdateStatus _updateStatus = const UpdateUnknown();
  SystemVolumeState _systemVolumeState = SystemVolumeState.initial();
  DateTime? _lastPetCryAt;
  Duration _nextPetCryCooldown = Duration.zero;
  DateTime? _lastSystemEventAt;

  /* Constructor */

  AnchwattViewModel({Duration levelUpDwell = defaultLevelUpDwell}) : _levelUpDwell = levelUpDwell {
    _bootServices();
  }

  /* Getters */

  int get level => _level;
  int get xp => _xp;
  int get xpToNextLevel => AnchwattSettings.xpForLevel(_level);
  Evolution get evolution => Evolution.fromLevel(_level);
  double get progress => (_xp / xpToNextLevel).clamp(0, 1);
  UpdateStatus get updateStatus => _updateStatus;
  SystemVolumeState get systemVolumeState => _systemVolumeState;
  ValueNotifier<SoundMode> get soundModeNotifier => _soundService.modeNotifier;
  ValueNotifier<bool> get silentModeNotifier => _silentModeService.enabledNotifier;
  Stream<int> get xpGainStream => _xpGainController.stream;

  /* Methods */

  Future<void> toggleSoundMode() => _soundService.toggleMode();

  Future<void> toggleSilentMode() => _silentModeService.toggle();

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
    notifyListeners();

    try {
      await _silentModeService.init();
      _silentModeService.enabledNotifier.addListener(_onSilentModeChanged);
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: SilentModeService init failed: $error');
    }

    try {
      await _soundService.init();
    } on Object catch (error) {
      debugPrint('AnchwattViewModel: SoundService init failed: $error');
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
    if (_level >= AnchwattSettings.levelMax) {
      return;
    }

    _xp += amount;
    _xpGainController.add(amount);

    while (_xp >= AnchwattSettings.xpForLevel(_level) && _level < AnchwattSettings.levelMax) {
      final int cost = AnchwattSettings.xpForLevel(_level);
      final int carry = _xp - cost;

      _xp = cost;
      notifyListeners();

      await Future<void>.delayed(_levelUpDwell);

      _level += 1;
      _xp = carry;
    }

    if (_level >= AnchwattSettings.levelMax) {
      _level = AnchwattSettings.levelMax;
      _xp = AnchwattSettings.xpForLevel(AnchwattSettings.levelMax);
    }

    notifyListeners();

    await _storage.writeProgression(level: _level, xp: _xp);
  }

  @override
  void dispose() {
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
    _silentModeService.enabledNotifier.removeListener(_onSilentModeChanged);
    _silentModeService.dispose();
    _soundService.dispose();
    _xpGainController.close();
    super.dispose();
  }
}
