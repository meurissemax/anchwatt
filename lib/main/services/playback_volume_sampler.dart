import 'dart:async';

import 'package:anchwatt/main/models.dart';

class PlaybackVolumeSampler {
  /* Variables */

  StreamSubscription<SystemVolumeState>? _subscription;
  final List<({DateTime at, double volume})> _samples = [];
  bool _stopped = false;

  /* Constructor */

  PlaybackVolumeSampler({
    required Stream<SystemVolumeState> volumeStream,
    required double initialVolume,
  }) {
    final DateTime now = DateTime.now();
    _samples.add((at: now, volume: initialVolume.clamp(0.0, 1.0)));
    _subscription = volumeStream.listen((SystemVolumeState state) {
      final double effective = state.muted ? 0.0 : state.volume.clamp(0.0, 1.0);
      _samples.add((at: DateTime.now(), volume: effective));
    });
  }

  /* Methods */

  // Stops sampling, unsubscribes, and returns the time-weighted mean volume
  // over the playback window. Falls back to the initial sample when no
  // further sample was recorded (playback shorter than the first emission).
  double stop() {
    if (_stopped) {
      return _samples.first.volume;
    }
    _stopped = true;
    _subscription?.cancel();
    _subscription = null;

    final DateTime end = DateTime.now();
    if (_samples.length == 1) {
      return _samples.first.volume;
    }

    // Piecewise constant: each sample's volume is held until the next sample
    // (or the playback end for the last one).
    double integralUs = 0;
    for (int i = 0; i < _samples.length - 1; i++) {
      final double dtUs = _samples[i + 1].at.difference(_samples[i].at).inMicroseconds.toDouble();
      integralUs += _samples[i].volume * dtUs;
    }
    final double tailUs = end.difference(_samples.last.at).inMicroseconds.toDouble();
    integralUs += _samples.last.volume * tailUs;

    final double totalUs = end.difference(_samples.first.at).inMicroseconds.toDouble();
    if (totalUs <= 0) {
      return _samples.first.volume;
    }

    return integralUs / totalUs;
  }
}
