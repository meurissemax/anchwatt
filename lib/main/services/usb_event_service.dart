import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UsbEventService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/usb_events';
  // Wide enough to absorb the connect → disconnect → reconnect handshake some
  // USB devices (notably iPhones, which renegotiate their USB configuration)
  // emit during enumeration. Each step lands as a distinct IOKit registry entry
  // and would otherwise trigger a second sound ~1s after the first.
  static const Duration _debounceWindow = Duration(milliseconds: 1500);
  static const Duration _startupGuard = Duration(milliseconds: 500);

  /* Variables */

  final EventChannel _channel = const EventChannel(_channelName);
  final StreamController<void> _controller = StreamController<void>.broadcast();

  StreamSubscription<dynamic>? _nativeSubscription;
  DateTime? _startedAt;
  DateTime? _lastEmittedAt;

  /* Getters */

  Stream<void> get events => _controller.stream;

  /* Methods */

  Future<void> start() async {
    if (_nativeSubscription != null) {
      return;
    }

    _startedAt = DateTime.now();
    _nativeSubscription = _channel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object error) => debugPrint('UsbEventService error: $error'),
    );
  }

  Future<void> stop() async {
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _startedAt = null;
    _lastEmittedAt = null;
  }

  void _onNativeEvent(Object? _) {
    final DateTime now = DateTime.now();

    final DateTime? startedAt = _startedAt;
    if (startedAt != null && now.difference(startedAt) < _startupGuard) {
      return;
    }

    final DateTime? last = _lastEmittedAt;
    if (last != null && now.difference(last) < _debounceWindow) {
      return;
    }

    _lastEmittedAt = now;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
