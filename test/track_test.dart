import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/core/track.dart';

void main() {
  group('Track', () {
    test('generated track loops back to level ground', () {
      final track = Track.generate(seed: 42);
      expect(track.count, greaterThanOrEqualTo(1600));
      expect(track.segments.first.y1, 0);
      expect(track.segments.last.y2.abs(), lessThan(1e-6));
      expect(track.segments.last.curve.abs(), lessThan(1e-6));
    });

    test('same seed gives the same layout', () {
      final a = Track.generate(seed: 7);
      final b = Track.generate(seed: 7);
      expect(a.count, b.count);
      for (var i = 0; i < a.count; i += 97) {
        expect(a.segments[i].curve, b.segments[i].curve);
        expect(a.segments[i].y2, b.segments[i].y2);
      }
    });

    test('segments are continuous in height', () {
      final track = Track.generate(seed: 3);
      for (var i = 1; i < track.count; i++) {
        expect(track.segments[i].y1, track.segments[i - 1].y2);
      }
    });

    test('wrap and signedDistance handle the loop seam', () {
      final track = Track.flat(100);
      final len = track.length;
      expect(track.wrap(-GameConfig.segmentLength), len - GameConfig.segmentLength);
      expect(track.signedDistance(len - 100, 100), 200);
      expect(track.signedDistance(100, len - 100), -200);
      expect(track.segmentAt(len + 250).index, 1);
    });
  });
}
