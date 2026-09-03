import '../core/game_config.dart';
import 'ghost_trace.dart';

/// Samples the player's progress a few times per second during a run.
class GhostRecorder {
  GhostRecorder({this.sampleInterval = GameConfig.ghostSampleInterval});

  final double sampleInterval;
  final List<GhostSample> _samples = [];
  double _nextSampleAt = 0;

  int get sampleCount => _samples.length;

  void reset() {
    _samples.clear();
    _nextSampleAt = 0;
  }

  /// Call every simulation frame; only records when [runTime] has passed the
  /// next sample point, so the list grows at ~1/[sampleInterval] Hz.
  void tick(double runTime, {required double distanceMeters, required int lane}) {
    if (runTime < _nextSampleAt) return;
    _nextSampleAt = runTime + sampleInterval;
    _samples.add(GhostSample(t: runTime, distanceMeters: distanceMeters, lane: lane));
  }

  GhostTrace finish() => GhostTrace(List.of(_samples));
}
