import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LaunchAtLoginService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/launch_at_login';

  /* Variables */

  final MethodChannel _channel = const MethodChannel(_channelName);
  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);

  /* Getters */

  bool get isEnabled => enabledNotifier.value;

  /* Methods */

  Future<void> refresh() async {
    final bool enabled = await _channel.invokeMethod<bool>('isEnabled') ?? false;
    enabledNotifier.value = enabled;
  }

  Future<void> setEnabled(bool value) async {
    try {
      await _channel.invokeMethod<void>('setEnabled', value);
      enabledNotifier.value = value;
    } on Object {
      // Resync from native state so the UI mirrors the real OS-side status
      // after a failed register/unregister attempt.
      await _safeRefresh();
      rethrow;
    }
  }

  Future<void> _safeRefresh() async {
    try {
      await refresh();
    } on Object catch (error) {
      debugPrint('LaunchAtLoginService: refresh after failure failed: $error');
    }
  }

  void dispose() {
    enabledNotifier.dispose();
  }
}
