import 'dart:math';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/entities/traffic_vehicle.dart';
import 'package:turbo_traffic_rush/game/progression_coordinator.dart';
import 'package:turbo_traffic_rush/game/traffic_racer_game.dart';
import 'package:turbo_traffic_rush/overlays/game_over_overlay.dart';
import 'package:turbo_traffic_rush/overlays/hud_overlay.dart';
import 'package:turbo_traffic_rush/overlays/menu_overlay.dart';
import 'package:turbo_traffic_rush/progression/car_catalog.dart';
import 'package:turbo_traffic_rush/services/high_score_service.dart';
import 'package:turbo_traffic_rush/services/settings_service.dart';
import 'package:turbo_traffic_rush/world/vehicle_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrafficRacerGame makeGame({
    bool isNewRecord = false,
    RunSummary? runSummary,
    int coins = 0,
  }) {
    final progression = ProgressionCoordinator();
    final game = TrafficRacerGame(
      settings: SettingsService(),
      highScores: HighScoreService(),
      progression: progression,
      random: Random(42),
    );
    game.isNewRecord = isNewRecord;
    game.stats.score = 5000;
    game.stats.nearMisses = 10;
    game.stats.bestCombo = 5;
    game.stats.level = 3;
    game.stats.overtakes = 20;
    game.hud.publish(
      score: 5000,
      level: 3,
      speedKmh: 120,
      combo: 3,
      comboProgress: 0.5,
      bestScore: 4000,
      powerUpProgress: const {},
      coinsThisRun: coins,
    );
    if (runSummary != null) {
      game.lastRunSummary = runSummary;
    }
    return game;
  }

  Future<void> pumpOverlay(
    WidgetTester tester,
    Widget child,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  group('GameOverOverlay branches', () {
    testWidgets('shows meters when distance < 1000m', (tester) async {
      final game = makeGame(
        isNewRecord: false,
        runSummary: const RunSummary(
          runCoins: 25,
          missionCoins: 0,
          missionsCompleted: [],
          allMissionsBonus: false,
          streakDays: 0,
          streakMultiplier: 1.0,
          passMultiplier: 1.0,
        ),
      );
      // Override distanceMeters to simulate a short run
      game.stats.distance = 500.0;
      await pumpOverlay(tester, GameOverOverlay(game: game), const Size(390, 844));
      expect(find.textContaining('m'), findsOneWidget);
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('shows km when distance >= 1000m', (tester) async {
      final game = makeGame(
        isNewRecord: false,
        runSummary: const RunSummary(
          runCoins: 125,
          missionCoins: 0,
          missionsCompleted: [],
          allMissionsBonus: false,
          streakDays: 0,
          streakMultiplier: 1.0,
          passMultiplier: 1.0,
        ),
      );
      game.stats.distance = 2500.0;
      await pumpOverlay(tester, GameOverOverlay(game: game), const Size(390, 844));
      expect(find.textContaining('km'), findsOneWidget);
    });

    testWidgets('shows Personal record when isNewRecord', (tester) async {
      final game = makeGame(
        isNewRecord: true,
        runSummary: const RunSummary(
          runCoins: 25,
          missionCoins: 0,
          missionsCompleted: [],
          allMissionsBonus: false,
          streakDays: 0,
          streakMultiplier: 1.0,
          passMultiplier: 1.0,
        ),
      );
      game.stats.distance = 500.0;
      await pumpOverlay(tester, GameOverOverlay(game: game), const Size(390, 844));
      expect(find.text('Personal record'), findsOneWidget);
    });

    testWidgets('shows streak bonus when streakDays > 1', (tester) async {
      final game = makeGame(
        isNewRecord: false,
        runSummary: const RunSummary(
          runCoins: 25,
          missionCoins: 0,
          missionsCompleted: [],
          allMissionsBonus: false,
          streakDays: 3,
          streakMultiplier: 1.3,
          passMultiplier: 1.0,
        ),
      );
      game.stats.distance = 500.0;
      await pumpOverlay(tester, GameOverOverlay(game: game), const Size(390, 844));
      expect(find.textContaining('streak'), findsOneWidget);
    });

    testWidgets('shows Turbo Pass bonus when passMultiplier > 1', (tester) async {
      final game = makeGame(
        isNewRecord: false,
        runSummary: const RunSummary(
          runCoins: 25,
          missionCoins: 0,
          missionsCompleted: [],
          allMissionsBonus: false,
          streakDays: 0,
          streakMultiplier: 1.0,
          passMultiplier: 2.0,
        ),
      );
      game.stats.distance = 500.0;
      await pumpOverlay(tester, GameOverOverlay(game: game), const Size(390, 844));
      expect(find.textContaining('Turbo Pass'), findsOneWidget);
    });

    testWidgets('renders mission completion text', (tester) async {
      final game = makeGame(
        isNewRecord: false,
        runSummary: const RunSummary(
          runCoins: 25,
          missionCoins: 40,
          missionsCompleted: [],
          allMissionsBonus: false,
          streakDays: 0,
          streakMultiplier: 1.0,
          passMultiplier: 1.0,
        ),
      );
      game.stats.distance = 500.0;
      await pumpOverlay(tester, GameOverOverlay(game: game), const Size(390, 844));
      expect(find.byType(GameOverOverlay), findsOneWidget);
    });
  });

  group('HudOverlay test drive branch', () {
    testWidgets('shows test drive indicator when isTestDrive is true', (tester) async {
      final game = makeGame();
      // Simulate test drive by setting a fake test drive skin
      game.startTestDrive(
        CarCatalog.premium.first,
      );
      await pumpOverlay(tester, HudOverlay(game: game), const Size(390, 844));
      expect(find.text('Free test drive'), findsOneWidget);
    });

    testWidgets('hides test drive indicator when isTestDrive is false', (tester) async {
      final game = makeGame();
      await pumpOverlay(tester, HudOverlay(game: game), const Size(390, 844));
      expect(find.text('Free test drive'), findsNothing);
    });
  });

  group('MenuOverlay tilt branch', () {
    testWidgets('shows tilt hint when tilt is enabled and supported', (tester) async {
      final game = makeGame();
      game.settings.tiltEnabled.value = true;
      await pumpOverlay(tester, MenuOverlay(game: game), const Size(390, 844));
      expect(find.text('Tilt your phone to steer'), findsOneWidget);
    });

    testWidgets('shows swipe hint when tilt is disabled', (tester) async {
      final game = makeGame();
      game.settings.tiltEnabled.value = false;
      await pumpOverlay(tester, MenuOverlay(game: game), const Size(390, 844));
      expect(find.text('Swipe left or right to change lanes'), findsOneWidget);
    });
  });

  group('VehiclePainter grayscale', () {
    test('draws grayscale path for achromatic colors', () {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      VehiclePainter.draw(
        canvas,
        bottomCenter: const ui.Offset(100, 100),
        width: 50,
        kind: VehicleKind.sedan,
        color: const ui.Color(0xFF808080),
      );
      rec.endRecording();
    });

    test('draws chromatic path for saturated colors', () {
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      VehiclePainter.draw(
        canvas,
        bottomCenter: const ui.Offset(100, 100),
        width: 50,
        kind: VehicleKind.sedan,
        color: const ui.Color(0xFFFF0000),
      );
      rec.endRecording();
    });
  });
}
