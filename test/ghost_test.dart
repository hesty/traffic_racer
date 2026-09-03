import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/progression/ghost_player.dart';
import 'package:turbo_traffic_rush/progression/ghost_recorder.dart';
import 'package:turbo_traffic_rush/progression/ghost_trace.dart';

void main() {
  group('GhostRecorder', () {
    test('samples at the configured rate, not every frame', () {
      final r = GhostRecorder(sampleInterval: 0.5);
      for (var i = 0; i <= 600; i++) {
        r.tick(i / 60, distanceMeters: i * 0.6, lane: 1);
      }
      // 10 seconds at 0.5 s -> 21 samples including t = 0.
      expect(r.sampleCount, 21);
      final trace = r.finish();
      expect(trace.samples.first.t, 0);
      expect(trace.finalDistanceMeters, closeTo(360, 0.01));
      r.reset();
      expect(r.sampleCount, 0);
    });
  });

  group('GhostTrace', () {
    test('round-trips through compact json', () {
      final trace = GhostTrace(const [
        GhostSample(t: 0, distanceMeters: 0, lane: 1),
        GhostSample(t: 0.5, distanceMeters: 18.5, lane: 2),
      ]);
      final copy = GhostTrace.fromJson(trace.toJson());
      expect(copy.samples.length, 2);
      expect(copy.samples.last.distanceMeters, 18.5);
      expect(copy.samples.last.lane, 2);
      expect(copy.finalTime, 0.5);
    });
  });

  group('GhostPlayer', () {
    final trace = GhostTrace(const [
      GhostSample(t: 0, distanceMeters: 0, lane: 1),
      GhostSample(t: 1, distanceMeters: 40, lane: 1),
      GhostSample(t: 2, distanceMeters: 100, lane: 0),
    ]);

    test('interpolates between samples', () {
      final p = GhostPlayer(trace);
      final s = GhostPlayerState();
      p.sampleInto(0.5, s);
      expect(s.distanceMeters, 20);
      expect(s.finished, isFalse);
      p.sampleInto(1.75, s);
      expect(s.distanceMeters, 85);
      expect(s.lane, 0);
    });

    test('parks at the end once the trace runs out', () {
      final p = GhostPlayer(trace);
      final s = GhostPlayerState();
      p.sampleInto(5, s);
      expect(s.distanceMeters, 100);
      expect(s.finished, isTrue);
      p.reset();
      p.sampleInto(0.25, s);
      expect(s.distanceMeters, 10);
    });

    test('handles an empty trace', () {
      final s = GhostPlayerState();
      GhostPlayer(const GhostTrace([])).sampleInto(3, s);
      expect(s.finished, isTrue);
    });
  });
}
