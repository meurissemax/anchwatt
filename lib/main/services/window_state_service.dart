import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WindowStateService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/window_state';

  /* Variables */

  final MethodChannel _channel;

  /* Constructor */

  WindowStateService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(_channelName);

  /* Methods */

  Future<bool> isWindowHidden() async {
    try {
      final bool? hidden = await _channel.invokeMethod<bool>('isWindowHidden');

      return hidden ?? false;
    } on Object catch (error) {
      debugPrint('WindowStateService: isWindowHidden failed: $error');

      return false;
    }
  }

  Future<void> showWindow() async {
    try {
      await _channel.invokeMethod<void>('showWindow');
    } on Object catch (error) {
      debugPrint('WindowStateService: showWindow failed: $error');
    }
  }
}
