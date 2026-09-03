import 'ghost_trace.dart';

/// Scratch object filled by [GhostPlayer.sampleInto] every frame.
class GhostPlayerState {
  double distanceMeters = 0;
  int lane = 1;

  /// True once the replay has run past its last sample; the ghost then parks
  /// at its final distance.
  bool finished = false;
}

/// Replays a [GhostTrace] by interpolating between samples.
class GhostPlayer {
  GhostPlayer(this.trace);

  final GhostTrace trace;
  int _cursor = 0;

  void reset() => _cursor = 0;

  /// Fills [out] with the ghost's position at run time [t]. Time only moves
  /// forward within a run, so the cursor never rewinds.
  void sampleInto(double t, GhostPlayerState out) {
    final samples = trace.samples;
    if (samples.isEmpty) {
      out
        ..distanceMeters = 0
        ..finished = true;
      return;
    }
    while (_cursor < samples.length - 1 && samples[_cursor + 1].t <= t) {
      _cursor++;
    }
    final a = samples[_cursor];
    if (_cursor >= samples.length - 1) {
      out
        ..distanceMeters = a.distanceMeters
        ..lane = a.lane
        ..finished = true;
      return;
    }
    final b = samples[_cursor + 1];
    final span = b.t - a.t;
    final f = span <= 0 ? 1.0 : ((t - a.t) / span).clamp(0.0, 1.0);
    out
      ..distanceMeters = a.distanceMeters + (b.distanceMeters - a.distanceMeters) * f
      ..lane = f < 0.5 ? a.lane : b.lane
      ..finished = false;
  }
}
