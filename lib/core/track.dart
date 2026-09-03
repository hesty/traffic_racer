import 'dart:math' as math;

import 'game_config.dart';
import 'projection.dart';

/// One road segment: the strip of road between two z planes.
class Segment {
  Segment({
    required this.index,
    required this.y1,
    required this.y2,
    required this.curve,
  });

  final int index;

  /// Hill height at the near / far edge.
  final double y1;
  final double y2;

  /// Per-segment lateral curvature (accumulated during rendering).
  final double curve;

  double get z1 => index * GameConfig.segmentLength;
  double get z2 => (index + 1) * GameConfig.segmentLength;

  /// Alternating colour band so the road appears to move.
  bool get isDarkBand =>
      (index ~/ GameConfig.rumbleLength).isEven;

  /// Screen-space projection scratch, filled by the renderer each frame.
  final ScreenPoint p1 = ScreenPoint();
  final ScreenPoint p2 = ScreenPoint();

  /// Lowest visible y on screen for this segment (used to clip sprites hidden
  /// behind hill crests).
  double clip = 0;

  /// Render frame counter stamped when the segment was visible.
  int frame = -1;
}

/// A looping procedurally-generated track with curves and hills.
class Track {
  Track._(this.segments);

  final List<Segment> segments;

  int get count => segments.length;
  double get length => count * GameConfig.segmentLength;

  /// Normalises [z] into `[0, length)`.
  double wrap(double z) {
    final m = z % length;
    return m < 0 ? m + length : m;
  }

  /// Signed shortest distance from [from] to [to] along the loop.
  double signedDistance(double from, double to) {
    var d = wrap(to) - wrap(from);
    if (d > length / 2) d -= length;
    if (d < -length / 2) d += length;
    return d;
  }

  Segment segmentAt(double z) =>
      segments[(wrap(z) / GameConfig.segmentLength).floor() % count];

  /// Interpolated hill height at [z].
  double heightAt(double z) {
    final s = segmentAt(z);
    final t = (wrap(z) - s.z1) / GameConfig.segmentLength;
    return lerp(s.y1, s.y2, t);
  }

  /// Builds a random track. The same [seed] always yields the same layout.
  factory Track.generate({int seed = 0, int targetSegments = 1600}) {
    final rng = math.Random(seed);
    final builder = _TrackBuilder();

    builder.straight(60);
    while (builder.count < targetSegments) {
      final roll = rng.nextDouble();
      final len = 40 + rng.nextInt(60);
      final dir = rng.nextBool() ? 1.0 : -1.0;
      if (roll < 0.30) {
        builder.straight(len);
      } else if (roll < 0.60) {
        builder.section(len ~/ 3, len ~/ 3, len ~/ 3,
            curve: dir * (1.5 + rng.nextDouble() * 2.5), hill: 0);
      } else if (roll < 0.80) {
        builder.section(len ~/ 3, len ~/ 3, len ~/ 3,
            curve: 0, hill: dir * (5 + rng.nextInt(10)));
      } else {
        builder.section(len ~/ 3, len ~/ 3, len ~/ 3,
            curve: dir * (1 + rng.nextDouble() * 2),
            hill: -dir * (4 + rng.nextInt(8)));
      }
    }
    // Return to level ground so the loop is seamless.
    builder.section(30, 20, 30,
        curve: 0, hill: -builder.lastY / GameConfig.segmentLength);
    builder.straight(20);
    return Track._(builder.segments);
  }

  /// A flat straight track, mainly for tests.
  factory Track.flat(int segments) {
    final b = _TrackBuilder();
    b.straight(segments);
    return Track._(b.segments);
  }
}

class _TrackBuilder {
  final List<Segment> segments = [];

  int get count => segments.length;
  double get lastY => segments.isEmpty ? 0 : segments.last.y2;

  void add(double curve, double y) {
    segments.add(Segment(index: count, y1: lastY, y2: y, curve: curve));
  }

  void straight(int n) => section(n, 0, 0, curve: 0, hill: 0);

  void section(int enter, int hold, int leave,
      {required double curve, required double hill}) {
    final startY = lastY;
    final endY = startY + hill * GameConfig.segmentLength;
    final total = enter + hold + leave;
    // Height uses (n + 1) so the section's last segment lands exactly on
    // [endY]; this keeps hills continuous and the loop seam flat.
    for (var n = 0; n < enter; n++) {
      add(easeIn(0, curve, n / enter), easeInOut(startY, endY, (n + 1) / total));
    }
    for (var n = 0; n < hold; n++) {
      add(curve, easeInOut(startY, endY, (enter + n + 1) / total));
    }
    for (var n = 0; n < leave; n++) {
      add(easeInOut(curve, 0, n / leave),
          easeInOut(startY, endY, (enter + hold + n + 1) / total));
    }
  }
}
