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
  void maintain({
    required double playerZ,
    required double playerSpeed,
    required int level,
  }) {
    final target = GameConfig.trafficCountForLevel(level);
    var attempts = 0;
    while (vehicles.length < target && attempts < 20) {
      attempts++;
      _trySpawn(playerZ, playerSpeed);
    }
  }

  void _trySpawn(double playerZ, double playerSpeed) {
    final ahead = GameConfig.minSpawnAhead +
        _rng.nextDouble() *
            (GameConfig.maxSpawnAhead - GameConfig.minSpawnAhead);
    final z = track.wrap(playerZ + ahead);
    final lane = _rng.nextInt(GameConfig.laneCount);
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
  bool _leavesAGap(double z, int lane) {
    const window = GameConfig.segmentLength * 10;
    final blocked = <int>{lane};
    for (final v in vehicles) {
      if (track.signedDistance(v.z, z).abs() < window) blocked.add(v.lane);
    }
    return blocked.length < GameConfig.laneCount;
  }

  /// Moves traffic and drops anything far behind the player.
  void update(double dt, {required double playerZ}) {
    for (final v in vehicles) {
      _followLeader(v);
      v.z = track.wrap(v.z + v.speed * dt);
    }
    vehicles.removeWhere((v) {
      final rel = track.signedDistance(playerZ, v.z);
      return rel < -GameConfig.despawnBehind;
    });
  }

  /// Simple car-following so vehicles never drive through each other.
  void _followLeader(TrafficVehicle v) {
    TrafficVehicle? leader;
    var leaderGap = double.infinity;
    for (final other in vehicles) {
      if (identical(other, v) || other.lane != v.lane) continue;
      final gap = track.signedDistance(v.z, other.z);
      if (gap > 0 && gap < leaderGap) {
        leader = other;
        leaderGap = gap;
      }
    }
    v.braking = false;
    if (leader != null && leaderGap < GameConfig.sameLaneGap * 0.6) {
      if (v.speed > leader.speed) {
        v.speed = leader.speed;
        v.braking = true;
      }
    }
  }
}
