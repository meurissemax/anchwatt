import 'dart:async';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/sound_service.dart';
import 'package:anchwatt/main/services/system_volume_service.dart';
import 'package:anchwatt/main/services/update_service.dart';
import 'package:anchwatt/main/services/usb_event_service.dart';
import 'package:anchwatt/main/storages/anchwatt_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeViewModel extends ChangeNotifier {
  /* Static variables */

  static const Duration defaultLevelUpDwell = Duration(milliseconds: 500);

  /* Variables */

  final Duration _levelUpDwell;
  final AnchwattStorage _storage = AnchwattStorage();
  final UsbEventService _usbEventService = UsbEventService();
  final SoundService _soundService = SoundService();
  final UpdateService _updateService = UpdateService();
  final SystemVolumeService _systemVolumeService = SystemVolumeService();

  StreamSubscription<void>? _usbSubscription;
  StreamSubscription<SystemVolumeState>? _systemVolumeSubscription;
  int _level = AnchwattSettings.levelMin;
  int _xp = 0;
  Future<void>? _pending;
  UpdateStatus _updateStatus = const UpdateUnknown();
  SystemVolumeState _systemVolumeState = SystemVolumeState.initial();

  /* Constructor */

  HomeViewModel({Duration levelUpDwell = defaultLevelUpDwell}) : _levelUpDwell = levelUpDwell {
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

  /* Methods */

  Future<void> addXp([int amount = AnchwattSettings.xpPerEvent]) {
    final Future<void> next = (_pending ?? Future<void>.value()).then((_) => _process(amount));
    _pending = next;

    next.whenComplete(() {
      if (identical(_pending, next)) {
        _pending = null;
      }
    });

    return next;
  }

  Future<void> _bootServices() async {
    await _storage.init();
    final ({int level, int xp}) initial = _storage.readProgression();
    _level = initial.level;
    _xp = initial.xp;
    notifyListeners();

    try {
      await _soundService.init();
    } on Object catch (error) {
      debugPrint('HomeViewModel: SoundService init failed: $error');
    }

    try {
      await _usbEventService.start();
      _usbSubscription = _usbEventService.events.listen((_) {
        _soundService.playRandom();
        addXp();
      });
    } on Object catch (error) {
      debugPrint('HomeViewModel: UsbEventService start failed: $error');
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
      debugPrint('HomeViewModel: SystemVolumeService start failed: $error');
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

  Future<void> _process(int amount) async {
    if (_level >= AnchwattSettings.levelMax) {
      return;
    }

    _xp += amount;

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
    _systemVolumeSubscription?.cancel();
    _systemVolumeService.stop();
    _soundService.dispose();
    super.dispose();
  }
}
