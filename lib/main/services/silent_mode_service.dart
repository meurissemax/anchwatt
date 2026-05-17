import 'package:anchwatt/main/storages/silent_mode_storage.dart';
import 'package:flutter/foundation.dart';

class SilentModeService {
  /* Variables */

  final SilentModeStorage _storage = SilentModeStorage();
  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);

  /* Getters */

  bool get isEnabled => enabledNotifier.value;

  /* Methods */

  Future<void> init() async {
    await _storage.init();
    enabledNotifier.value = _storage.readEnabled();
  }

  Future<void> setEnabled(bool value) async {
    if (enabledNotifier.value == value) {
      return;
    }

    enabledNotifier.value = value;
    await _storage.writeEnabled(value);
  }

  Future<void> toggle() => setEnabled(!enabledNotifier.value);

  void dispose() {
    enabledNotifier.dispose();
  }
}
