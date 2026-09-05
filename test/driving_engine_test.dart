import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_traffic_rush/core/swept_collision.dart';
import 'package:turbo_traffic_rush/entities/traffic_vehicle.dart';
import 'package:turbo_traffic_rush/game/progression_coordinator.dart';
import 'package:turbo_traffic_rush/game/traffic_racer_game.dart';
import 'package:turbo_traffic_rush/progression/car_catalog.dart';
import 'package:turbo_traffic_rush/services/high_score_service.dart';
import 'package:turbo_traffic_rush/services/settings_service.dart';

Future<TrafficRacerGame> makeGame() async {
  final game = TrafficRacerGame(
    settings: SettingsService(),
    highScores: HighScoreService(),
    progression: ProgressionCoordinator(),
    random: Random(42),
  );
  for (final name in [
    Overlays.menu,
    Overlays.hud,
    Overlays.pause,
    Overlays.gameOver,
    Overlays.garage,
    Overlays.paywall,
  ]) {
    game.overlays.addEntry(name, (_, _) => const SizedBox());
  }
  game.onGameResize(Vector2(390, 844));
  await game.onLoad();
  return game;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'swept collision catches tunnelling but rejects different crossing times',
    () {
      expect(
        sweptCollision(
          fromZ: 500,
          toZ: -500,
          fromX: 0,
          toX: 0,
          halfLength: 100,
          halfWidth: 0.3,
        ),
        isTrue,
      );
      expect(
        sweptCollision(
          fromZ: 500,
          toZ: -500,
          fromX: 1,
          toX: 0.2,
          halfLength: 100,
          halfWidth: 0.3,
        ),
        isFalse,
      );
      expect(
        sweptCollision(
          fromZ: 50,
          toZ: 20,
          fromX: 0.8,
          toX: 0,
          halfLength: 100,
          halfWidth: 0.3,
        ),
        isTrue,
      );
    },
  );

  testWidgets('15, 30, 60 and 120 fps advance the same race', (tester) async {
    final distances = <double>[];
    final speeds = <double>[];
    for (final fps in [15, 30, 60, 120]) {
      final game = await makeGame();
      game.startRun();
      game.steer(1);
      for (var i = 0; i < fps * 2; i++) {
        game.update(1 / fps);
      }
      expect(game.runTime, closeTo(2, 1e-8));
      distances.add(game.stats.distance);
      speeds.add(game.speed);
      game.onRemove();
    }
    for (var i = 1; i < distances.length; i++) {
      expect(distances[i], closeTo(distances.first, 1e-8));
      expect(speeds[i], closeTo(speeds.first, 1e-8));
    }
  });

  testWidgets('pause freezes simulation and long stalls are bounded', (
    tester,
  ) async {
    final game = await makeGame();
    game.startRun();
    game.update(1 / 60);
    game.pauseRun();
    final time = game.runTime;
    game.shake = 8;
    game.update(10);
    expect(game.runTime, time);
    expect(game.shake, 8);
    game.resumeRun();
    game.update(10);
    expect(game.runTime - time, closeTo(0.1, 1e-8));
    game.onRemove();
  });

  testWidgets(
    'test drive lends one car for one run without unlocking the pass',
    (tester) async {
      final game = await makeGame();
      final skin = CarCatalog.premium.last;
      expect(game.startTestDrive(skin), isTrue);
      expect(game.selectedSkin, skin);
      expect(game.progression.purchases.isActive, isFalse);
      expect(game.progression.purchases.coinMultiplier, 1);
      game.traffic.vehicles.add(
        TrafficVehicle(
          kind: VehicleKind.sedan,
          color: const Color(0xFFFFFFFF),
          lane: game.player.lane,
          z: game.playerTrackZ,
          speed: 0,
        ),
      );
      game.update(1 / 60);
      expect(game.phase, GamePhase.crashing);
      for (var i = 0; i < 100; i++) {
        game.update(1 / 60);
      }
      expect(game.phase, GamePhase.gameOver);
      expect(game.lastTestDriveSkin, skin);
      expect(game.isTestDrive, isFalse);
      expect(game.selectedSkin.id, CarCatalog.defaultId);
      expect(game.startTestDrive(skin), isFalse);
      game.startRun();
      expect(game.phase, GamePhase.playing);
      expect(game.lastTestDriveSkin, isNull);
      game.onRemove();
    },
  );
}
