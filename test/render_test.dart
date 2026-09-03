import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/entities/traffic_vehicle.dart';
import 'package:turbo_traffic_rush/game/traffic_racer_game.dart';
import 'package:turbo_traffic_rush/services/high_score_service.dart';
import 'package:turbo_traffic_rush/services/settings_service.dart';
import 'package:turbo_traffic_rush/world/vehicle_painter.dart';

/// Renders into an offscreen picture: any exception thrown by a painter
/// (bad gradient stops, NaN geometry, ...) fails the test instead of
/// silently blanking part of the frame at runtime.
void main() {
  test('every vehicle kind paints at several sizes', () {
    for (final kind in VehicleKind.values) {
      for (final width in [1.0, 3.0, 24.0, 160.0]) {
        final rec = ui.PictureRecorder();
        final canvas = ui.Canvas(rec);
        VehiclePainter.draw(canvas,
            bottomCenter: const ui.Offset(200, 300),
            width: width,
            kind: kind,
            color: const ui.Color(0xFF1E88E5),
            braking: true,
            lightsAlpha: 0.5,
            isPlayer: kind == VehicleKind.sedan,
            nitro: 1.2,
            tilt: 0.1);
        rec.endRecording();
      }
    }
  });

  testWidgets('a full run renders hundreds of frames without throwing',
      (tester) async {
    final game = TrafficRacerGame(
      settings: SettingsService(),
      highScores: HighScoreService(),
      random: Random(5),
    );
    for (final name in [Overlays.menu, Overlays.hud, Overlays.pause, Overlays.gameOver]) {
      game.overlays.addEntry(name, (_, _) => const SizedBox());
    }
    game.onGameResize(Vector2(400, 800));
    await game.onLoad();
    game.startRun();
    final rng = Random(9);
    var runs = 1;
    for (var frame = 0; frame < 1500; frame++) {
      if (rng.nextDouble() < 0.04) game.steer(rng.nextBool() ? 1 : -1);
      game.update(1 / 60);
      if (game.phase == GamePhase.gameOver) {
        runs++;
        game.startRun();
      }
      final rec = ui.PictureRecorder();
      game.render(ui.Canvas(rec));
      rec.endRecording();
    }
    expect(game.stats.distance, greaterThan(0));
    expect(runs, greaterThanOrEqualTo(1));
  });
}
