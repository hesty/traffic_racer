/// One point of a recorded run: how far the player had driven at [t].
class GhostSample {
  const GhostSample({
    required this.t,
    required this.distanceMeters,
    required this.lane,
  });

  final double t;
  final double distanceMeters;
  final int lane;
}

/// The pace of a past run, stored as distance-over-time so it can be replayed
/// on any track (tracks are regenerated every run).
class GhostTrace {
  const GhostTrace(this.samples);

  final List<GhostSample> samples;

  bool get isEmpty => samples.isEmpty;
  double get finalDistanceMeters => isEmpty ? 0 : samples.last.distanceMeters;
  double get finalTime => isEmpty ? 0 : samples.last.t;

  /// Compact `[t, distance, lane]` triples.
  List<Object?> toJson() => [
        for (final s in samples) [s.t, s.distanceMeters, s.lane],
      ];

  factory GhostTrace.fromJson(List<Object?> json) => GhostTrace([
        for (final raw in json.cast<List>())
          GhostSample(
            t: (raw[0] as num).toDouble(),
            distanceMeters: (raw[1] as num).toDouble(),
            lane: (raw[2] as num).toInt(),
          ),
      ]);
}
