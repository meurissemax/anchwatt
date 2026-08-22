import 'package:anchwatt/main/storages/silent_mode_storage.dart';
import 'package:flutter/foundation.dart';

class SilentModeService {
  /* Variables */

  final SilentModeStorage _storage = SilentModeStorage();
  // OR of the two underlying sources — the single source of truth consumed by
  // the AppBar icon, sound gating and XP/event guards. Listeners only fire on
  // OR transitions, not on every flag flip.
  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);

  bool _manualEnabled = false;
  bool _calendarEnabled = false;

  /* Getters */

  bool get isEnabled => enabledNotifier.value;
  bool get calendarEnabled => _calendarEnabled;

  // Production code reads the combined [enabledNotifier]; this only exists so
  // tests can assert the manual flag in isolation.
  @visibleForTesting
  bool get manualEnabled => _manualEnabled;

  /* Methods */

  Future<void> init() async {
    await _storage.init();
    _manualEnabled = _storage.readEnabled();
    enabledNotifier.value = _manualEnabled || _calendarEnabled;
  }

  Future<void> setManualEnabled(bool value) async {
    if (_manualEnabled == value) {
      return;
    }

    _manualEnabled = value;
    _recomputeEnabled();
    await _storage.writeEnabled(value);
  }

  void setCalendarEnabled(bool value) {
    if (_calendarEnabled == value) {
      return;
    }

    _calendarEnabled = value;
    _recomputeEnabled();
  }

  void _recomputeEnabled() {
    final bool next = _manualEnabled || _calendarEnabled;
    if (enabledNotifier.value != next) {
      enabledNotifier.value = next;
    }
  }

  void dispose() {
    enabledNotifier.dispose();
  }
}
