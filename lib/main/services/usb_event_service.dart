import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UsbEventService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/usb_events';
  static const Duration _debounceWindow = Duration(milliseconds: 750);
  static const Duration _startupGuard = Duration(milliseconds: 500);

  /* Variables */

  final EventChannel _channel = const EventChannel(_channelName);
  final StreamController<void> _controller = StreamController<void>.broadcast();

  StreamSubscription<dynamic>? _nativeSubscription;
  Timer? _debounceTimer;
  DateTime? _startedAt;

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
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _startedAt = null;
  }

  void _onNativeEvent(Object? _) {
    final DateTime? startedAt = _startedAt;

    if (startedAt != null && DateTime.now().difference(startedAt) < _startupGuard) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceWindow, () {
      if (!_controller.isClosed) {
        _controller.add(null);
      }
    });
  }
}
