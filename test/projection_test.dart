import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/core/projection.dart';

void main() {
  group('Projector', () {
    final projector = Projector(screenWidth: 400, screenHeight: 800);

    test('road centre projects to horizontal screen centre', () {
      final p = ScreenPoint();
      projector.project(p,
          worldX: 0,
          worldY: 0,
          worldZ: 5000,
          cameraX: 0,
          cameraY: GameConfig.cameraHeight,
          cameraZ: 0);
      expect(p.x, closeTo(200, 1e-6));
      expect(p.y, greaterThan(400)); // below the horizon
      expect(p.cameraZ, 5000);
    });

    test('farther points are smaller and closer to the horizon', () {
      final near = ScreenPoint();
      final far = ScreenPoint();
      for (final (point, z) in [(near, 2000.0), (far, 20000.0)]) {
        projector.project(point,
            worldX: 0,
            worldY: 0,
            worldZ: z,
            cameraX: 0,
            cameraY: GameConfig.cameraHeight,
            cameraZ: 0);
      }
      expect(far.w, lessThan(near.w));
      expect(far.y, lessThan(near.y));
      expect(far.y, greaterThan(400));
    });

    test('player sits a few segments in front of the camera', () {
      expect(projector.playerZ, greaterThan(GameConfig.segmentLength));
      expect(projector.playerZ, lessThan(GameConfig.segmentLength * 10));
    });
  });

  test('lane centres are evenly spaced across the road', () {
    expect(GameConfig.laneCenter(0), closeTo(-2 / 3, 1e-9));
    expect(GameConfig.laneCenter(1), closeTo(0, 1e-9));
    expect(GameConfig.laneCenter(2), closeTo(2 / 3, 1e-9));
  });
}
