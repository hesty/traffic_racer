import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:turbo_traffic_rush/services/tilt_controller.dart';

void main() {
  group('TiltController', () {
    test('start sets isListening to true', () async {
      final controller = TiltController(
        onLaneChange: (d) {},
        streamFactory: ({Duration? samplingPeriod}) =>
            StreamController<AccelerometerEvent>().stream,
      );
      controller.start();
      expect(controller.isListening, isTrue);
      controller.stop();
    });

    test('stop sets isListening to false and resets armed state', () async {
      final controller = TiltController(
        onLaneChange: (d) {},
        streamFactory: ({Duration? samplingPeriod}) =>
            StreamController<AccelerometerEvent>().stream,
      );
      controller.start();
      expect(controller.isListening, isTrue);
      controller.stop();
      expect(controller.isListening, isFalse);
    });

    test('double start is a no-op', () async {
      var startCount = 0;
      final controller = TiltController(
        onLaneChange: (d) {},
        streamFactory: ({Duration? samplingPeriod}) {
          startCount++;
          return StreamController<AccelerometerEvent>().stream;
        },
      );
      controller.start();
      controller.start();
      expect(startCount, 1);
      controller.stop();
    });

    test('fires onLaneChange when tilt passes trigger threshold right',
        () async {
      final lanes = <int>[];
      final ctrl = StreamController<AccelerometerEvent>();
      final controller = TiltController(
        onLaneChange: lanes.add,
        streamFactory: ({Duration? samplingPeriod}) => ctrl.stream,
      );
      controller.start();
      ctrl.add(AccelerometerEvent(3.0, 0, 0, DateTime.now()));
      await Future.delayed(Duration.zero);
      expect(lanes, contains(1));
      controller.stop();
    });

    test('fires onLaneChange when tilt passes trigger threshold left',
        () async {
      final lanes = <int>[];
      final ctrl = StreamController<AccelerometerEvent>();
      final controller = TiltController(
        onLaneChange: lanes.add,
        streamFactory: ({Duration? samplingPeriod}) => ctrl.stream,
      );
      controller.start();
      ctrl.add(AccelerometerEvent(-3.0, 0, 0, DateTime.now()));
      await Future.delayed(Duration.zero);
      expect(lanes, contains(-1));
      controller.stop();
    });

    test('does not fire on sub-threshold tilt', () async {
      final lanes = <int>[];
      final ctrl = StreamController<AccelerometerEvent>();
      final controller = TiltController(
        onLaneChange: lanes.add,
        streamFactory: ({Duration? samplingPeriod}) => ctrl.stream,
      );
      controller.start();
      ctrl.add(AccelerometerEvent(1.0, 0, 0, DateTime.now()));
      await Future.delayed(Duration.zero);
      expect(lanes, isEmpty);
      controller.stop();
    });

    test('rearms only after tilt drops below release threshold', () async {
      final lanes = <int>[];
      final ctrl = StreamController<AccelerometerEvent>();
      final controller = TiltController(
        onLaneChange: lanes.add,
        streamFactory: ({Duration? samplingPeriod}) => ctrl.stream,
      );
      controller.start();
      // Trigger right
      ctrl.add(AccelerometerEvent(3.0, 0, 0, DateTime.now()));
      await Future.delayed(Duration.zero);
      expect(lanes.length, 1);
      // Stay above release threshold — should NOT fire again
      ctrl.add(AccelerometerEvent(2.0, 0, 0, DateTime.now()));
      await Future.delayed(Duration.zero);
      expect(lanes.length, 1, reason: 'should not fire while armed=false');
      // Drop below release
      ctrl.add(AccelerometerEvent(0.5, 0, 0, DateTime.now()));
      await Future.delayed(Duration.zero);
      // Now trigger left
      ctrl.add(AccelerometerEvent(-3.0, 0, 0, DateTime.now()));
      await Future.delayed(Duration.zero);
      expect(lanes, contains(-1));
      controller.stop();
    });

    test('onError calls stop and clears subscription', () async {
      final ctrl = StreamController<AccelerometerEvent>();
      final controller = TiltController(
        onLaneChange: (d) {},
        streamFactory: ({Duration? samplingPeriod}) => ctrl.stream,
      );
      controller.start();
      ctrl.addError('test error');
      await Future.delayed(Duration.zero);
      expect(controller.isListening, isFalse);
    });

    test('streamFactory throw is caught and cleared', () async {
      final controller = TiltController(
        onLaneChange: (d) {},
        streamFactory: ({Duration? samplingPeriod}) =>
            throw StateError('no sensor'),
      );
      controller.start();
      expect(controller.isListening, isFalse);
    });
  });
}
