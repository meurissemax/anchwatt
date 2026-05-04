import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HeadphonesEventService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/headphones_events';
  // Native side already filters to actual headphones-vs-other classification
  // toggles, but we briefly silence events immediately after start in case a
  // stale notification leaks through during the listener's initial wiring.
  static const Duration _startupGuard = Duration(milliseconds: 500);

  /* Variables */

  final EventChannel _channel = const EventChannel(_channelName);
  final StreamController<void> _controller = StreamController<void>.broadcast();

  StreamSubscription<dynamic>? _nativeSubscription;
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
      onError: (Object error) => debugPrint('HeadphonesEventService error: $error'),
    );
  }

  Future<void> stop() async {
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _startedAt = null;
  }

  void _onNativeEvent(Object? _) {
    final DateTime now = DateTime.now();

    final DateTime? startedAt = _startedAt;
    if (startedAt != null && now.difference(startedAt) < _startupGuard) {
      return;
    }

    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
