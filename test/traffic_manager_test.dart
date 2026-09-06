import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/core/track.dart';
import 'package:turbo_traffic_rush/game/traffic_manager.dart';

void main() {
  test('traffic never blocks every lane on the same stretch', () {
    final track = Track.generate(seed: 11);
    final manager = TrafficManager(track, random: Random(1));
    var playerZ = 0.0;
    for (var step = 0; step < 400; step++) {
      manager.maintain(playerZ: playerZ, level: 9);
      manager.update(1 / 30, playerZ: playerZ);
      playerZ = track.wrap(playerZ + 6000 / 30);

      for (final v in manager.vehicles) {
        final lanes = <int>{v.lane};
        for (final o in manager.vehicles) {
          if (track.signedDistance(v.z, o.z).abs() < GameConfig.blockWindow) {
            lanes.add(o.lane);
          }
        }
        expect(lanes.length, lessThan(GameConfig.laneCount),
            reason: 'all lanes blocked near z=${v.z}');
      }
    }
    expect(manager.vehicles, isNotEmpty);
  });

  test('avoidLane keeps the given lane empty', () {
    final track = Track.flat(400);
    final manager = TrafficManager(track, random: Random(3));
    manager.maintain(playerZ: 0, level: 5, avoidLane: 1);
    expect(manager.vehicles, isNotEmpty);
    expect(manager.vehicles.every((v) => v.lane != 1), isTrue);
  });

  test('vehicles spawn ahead of the player and get recycled behind', () {
    final track = Track.flat(400);
    final manager = TrafficManager(track, random: Random(2));
    manager.maintain(playerZ: 0, level: 1);
    for (final v in manager.vehicles) {
      final rel = track.signedDistance(0, v.z);
      expect(rel, greaterThanOrEqualTo(GameConfig.minSpawnAhead));
    }
    // Teleport the player far ahead: everything is now behind and dropped.
    manager.update(0, playerZ: GameConfig.maxSpawnAhead + GameConfig.despawnBehind * 2);
    expect(manager.vehicles, isEmpty);
  });

  test('clear empties all vehicles', () {
    final track = Track.flat(400);
    final manager = TrafficManager(track, random: Random(5));
    manager.maintain(playerZ: 0, level: 8);
    expect(manager.vehicles, isNotEmpty);
    manager.clear();
    expect(manager.vehicles, isEmpty);
  });

  test('zero-level maintains a minimum of five vehicles', () {
    final track = Track.flat(400);
    final manager = TrafficManager(track, random: Random(7));
    manager.maintain(playerZ: 0, level: 0);
    expect(manager.vehicles.length, 5);
  });
}
