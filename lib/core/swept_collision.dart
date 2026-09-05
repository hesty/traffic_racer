/// Whether two moving intervals overlap at the same instant during a step.
/// Relative positions are unwrapped before entering this function.
bool sweptCollision({
  required double fromZ,
  required double toZ,
  required double fromX,
  required double toX,
  required double halfLength,
  required double halfWidth,
}) {
  var enter = 0.0;
  var leave = 1.0;
  bool clip(double from, double to, double extent) {
    final delta = to - from;
    if (delta.abs() < 1e-10) return from.abs() < extent;
    final a = (-extent - from) / delta;
    final b = (extent - from) / delta;
    final low = a < b ? a : b;
    final high = a > b ? a : b;
    if (low > enter) enter = low;
    if (high < leave) leave = high;
    return enter < leave;
  }

  return clip(fromZ, toZ, halfLength) && clip(fromX, toX, halfWidth);
}
