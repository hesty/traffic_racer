import 'dart:math' as math;

import '../core/game_config.dart';

/// The player's car: a lane index plus a smoothed lateral offset.
class Player {
  int lane = GameConfig.laneCount ~/ 2;

  /// Normalised lateral position on the road (-1..1).
  double offset = GameConfig.laneCenter(GameConfig.laneCount ~/ 2);

  /// -1, 0 or 1 while a lane change is in progress (used for the visual
  /// steering tilt).
  int steer = 0;

  double lean = 0;

  double _from = 0;
  double _to = 0;
  double _t = 1;

  bool get isChangingLane => _t < 1;

  /// Attempts a lane change. Returns false when blocked by the road edge.
  bool changeLane(int direction) {
    final target = lane + direction;
    if (target < 0 || target >= GameConfig.laneCount) return false;
    lane = target;
    _from = offset;
    _to = GameConfig.laneCenter(target);
    _t = 0;
    steer = direction;
    return true;
  }

  void update(double dt) {
    lean +=
        ((isChangingLane ? steer.toDouble() : 0) - lean) *
        (1 - math.exp(-dt * 16));
    if (_t >= 1) return;
    _t = (_t + dt / GameConfig.laneChangeDuration).clamp(0.0, 1.0);
    // Smoothstep for a snappy but eased slide.
    final s = _t * _t * (3 - 2 * _t);
    offset = _from + (_to - _from) * s;
    if (_t >= 1) {
      offset = _to;
      steer = 0;
    }
  }

  void reset() {
    lane = GameConfig.laneCount ~/ 2;
    offset = GameConfig.laneCenter(lane);
    steer = 0;
    lean = 0;
    _t = 1;
  }
}
