import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Turns accelerometer tilt into discrete lane-change events.
///
/// A lane change fires when the phone tilts past [triggerThreshold]; the
/// controller then re-arms only after the phone returns under
/// [releaseThreshold], so holding a tilt never spams changes.
class TiltController {
  TiltController({
    required this.onLaneChange,
    Stream<AccelerometerEvent> Function({Duration samplingPeriod})
        streamFactory = accelerometerEventStream,
  }) : _streamFactory = streamFactory;

  final void Function(int direction) onLaneChange;
  final Stream<AccelerometerEvent> Function(
      {Duration samplingPeriod}) _streamFactory;

  static const double triggerThreshold = 2.4; // m/s^2 along the x axis
  static const double releaseThreshold = 1.1;

  StreamSubscription<AccelerometerEvent>? _sub;
  bool _armed = true;

  bool get isListening => _sub != null;

  void start() {
    if (_sub != null) return;
    try {
      _sub = _streamFactory(
        samplingPeriod: const Duration(milliseconds: 40),
      ).listen(_onEvent, onError: (Object e) {
        debugPrint('Accelerometer unavailable: $e');
        stop();
      });
    } catch (e) {
      debugPrint('Accelerometer unavailable: $e');
      _sub = null;
    }
  }

  void _onEvent(AccelerometerEvent e) {
    // In portrait, +x points to the right edge of the screen; tilting the
    // right side down gives a positive reading.
    final x = e.x;
    if (_armed && x.abs() > triggerThreshold) {
      _armed = false;
      onLaneChange(x > 0 ? 1 : -1);
    } else if (!_armed && x.abs() < releaseThreshold) {
      _armed = true;
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _armed = true;
  }
}
