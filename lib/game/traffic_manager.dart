import 'dart:math' as math;
import 'dart:ui';

import '../core/game_config.dart';
import '../core/track.dart';
import '../entities/traffic_vehicle.dart';

/// Spawns, moves and recycles AI traffic so the road always has something to
/// dodge without ever becoming impassable.
class TrafficManager {
  TrafficManager(this.track, {math.Random? random})
      : _rng = random ?? math.Random();

  final Track track;
  final math.Random _rng;
  final List<TrafficVehicle> vehicles = [];

  static const _palette = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFFF4511E),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFECEFF1),
    Color(0xFF546E7A),
    Color(0xFF6D4C41),
  ];

  void clear() => vehicles.clear();

  /// Keeps the vehicle count topped up for the current level.
  /// [avoidLane] keeps a lane clear of new spawns (used for the start grace
  /// period so the first seconds are never an instant crash).
  void maintain({
    required double playerZ,
    required int level,
    int? avoidLane,
  }) {
    final target = GameConfig.trafficCountForLevel(level);
    var attempts = 0;
    while (vehicles.length < target && attempts < 20) {
      attempts++;
      _trySpawn(playerZ, avoidLane);
    }
  }

  void _trySpawn(double playerZ, int? avoidLane) {
    final ahead = GameConfig.minSpawnAhead +
        _rng.nextDouble() *
            (GameConfig.maxSpawnAhead - GameConfig.minSpawnAhead);
    final z = track.wrap(playerZ + ahead);
    final lane = _rng.nextInt(GameConfig.laneCount);
    if (lane == avoidLane) return;
    if (!_laneIsFree(z, lane)) return;
    if (!_leavesAGap(z, lane)) return;

    final kind = _randomKind();
    final speedFactor = GameConfig.trafficSpeedMin +
        _rng.nextDouble() *
            (GameConfig.trafficSpeedMax - GameConfig.trafficSpeedMin);
    vehicles.add(TrafficVehicle(
      kind: kind,
      color: _palette[_rng.nextInt(_palette.length)],
      lane: lane,
      z: z,
      speed: GameConfig.baseSpeed * speedFactor,
    ));
  }

  VehicleKind _randomKind() {
    final r = _rng.nextDouble();
    if (r < 0.32) return VehicleKind.sedan;
    if (r < 0.55) return VehicleKind.hatchback;
    if (r < 0.72) return VehicleKind.suv;
    if (r < 0.84) return VehicleKind.van;
    if (r < 0.94) return VehicleKind.truck;
    return VehicleKind.bus;
  }

  bool _laneIsFree(double z, int lane) {
    for (final v in vehicles) {
      if (v.lane != lane) continue;
      if (track.signedDistance(v.z, z).abs() < GameConfig.sameLaneGap) {
        return false;
      }
    }
    return true;
  }

  /// Guarantees at least one lane stays open across every stretch of road.
  /// Uses a doubled window so the new vehicle cannot complete a wall for
  /// anyone already nearby.
  bool _leavesAGap(double z, int lane) {
    final blocked = <int>{lane};
    for (final v in vehicles) {
      if (track.signedDistance(v.z, z).abs() < GameConfig.blockWindow * 2) {
        blocked.add(v.lane);
      }
    }
    return blocked.length < GameConfig.laneCount;
  }

  /// Moves traffic and drops anything far behind the player.
  void update(double dt, {required double playerZ}) {
    for (final v in vehicles) {
      _regulateSpeed(v, dt);
    }
    for (final v in vehicles) {
      v.z = track.wrap(v.z + v.speed * dt);
    }
    vehicles.removeWhere((v) {
      final rel = track.signedDistance(playerZ, v.z);
      return rel < -GameConfig.despawnBehind;
    });
  }

  /// Car-following plus "wall" avoidance so the player always has a way
  /// through. A vehicle brakes (to the slowest vehicle ahead) when either:
  ///  * two vehicles ahead in the other lanes already sit within a window of
  ///    each other (a pair it must not join), or
  ///  * every other lane has traffic beside or ahead of it in the approach
  ///    range, so pressing on would line all lanes up.
  /// When unobstructed it eases back to its cruise speed.
  void _regulateSpeed(TrafficVehicle v, double dt) {
    const window = GameConfig.blockWindow;
    const approach = window * 1.5;
    double? cap;
    final nearLanes = <int>{};
    double? slowestAhead;

    for (final o in vehicles) {
      if (identical(o, v)) continue;
      final gap = track.signedDistance(v.z, o.z);

      if (o.lane == v.lane) {
        if (gap > 0 && gap < GameConfig.sameLaneGap * 0.6) {
          cap = _min(cap, o.speed);
        }
        continue;
      }
      if (gap.abs() >= approach) continue;
      nearLanes.add(o.lane);
      if (gap <= 0) continue;
      slowestAhead = _min(slowestAhead, o.speed);

      // Pair ahead: another lane occupied within a window of [o].
      for (final p in vehicles) {
        if (p.lane == v.lane || p.lane == o.lane) continue;
        if (track.signedDistance(o.z, p.z).abs() < window) {
          cap = _min(cap, math.min(o.speed, p.speed));
        }
      }
    }
    if (nearLanes.length >= GameConfig.laneCount - 1 && slowestAhead != null) {
      cap = _min(cap, slowestAhead);
    }

    if (cap != null && v.speed > cap) {
      v.speed = cap;
      v.braking = true;
    } else {
      v.braking = false;
      if (cap == null) {
        v.speed += (v.cruiseSpeed - v.speed) * math.min(1, dt * 0.4);
      }
    }
  }

  static double _min(double? a, double b) => a == null ? b : math.min(a, b);
}
