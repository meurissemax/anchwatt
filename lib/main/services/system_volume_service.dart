import 'dart:async';

import 'package:anchwatt/main/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemVolumeService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/system_volume';

  /* Variables */

  final EventChannel _channel = const EventChannel(_channelName);
  final StreamController<SystemVolumeState> _controller = StreamController<SystemVolumeState>.broadcast();

  StreamSubscription<dynamic>? _nativeSubscription;

  /* Getters */

  Stream<SystemVolumeState> get events => _controller.stream;

  /* Methods */

  Future<void> start() async {
    if (_nativeSubscription != null) {
      return;
    }

    _nativeSubscription = _channel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object error) => debugPrint('SystemVolumeService error: $error'),
    );
  }

  Future<void> stop() async {
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
  }

  void _onNativeEvent(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return;
    }

    final SystemVolumeState state = SystemVolumeState.fromMap(raw);

    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }
}
