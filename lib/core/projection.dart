import 'dart:math' as math;

import 'game_config.dart';

/// Result of projecting a world point onto the screen.
class ScreenPoint {
  double x = 0;
  double y = 0;

  /// Projected half road width in pixels at this depth.
  double w = 0;
  double scale = 0;

  /// Depth relative to the camera (positive = in front of camera).
  double cameraZ = 0;
}

/// Perspective projection for the classic "road segments" pseudo-3D renderer.
///
/// The camera sits `GameConfig.cameraHeight` above the road and looks straight
/// down the z axis. `cameraDepth` is `1 / tan(fov / 2)`.
class Projector {
  Projector({
    required this.screenWidth,
    required this.screenHeight,
    double fieldOfViewDegrees = GameConfig.fieldOfViewDegrees,
  }) : cameraDepth = 1 / math.tan((fieldOfViewDegrees / 2) * math.pi / 180);

  final double screenWidth;
  final double screenHeight;
  final double cameraDepth;

  /// Z distance from the camera to the player's car.
  double get playerZ => GameConfig.cameraHeight * cameraDepth;

  /// Projects a world point into [out].
  void project(
    ScreenPoint out, {
    required double worldX,
    required double worldY,
    required double worldZ,
    required double cameraX,
    required double cameraY,
    required double cameraZ,
  }) {
    final cx = worldX - cameraX;
    final cy = worldY - cameraY;
    final cz = worldZ - cameraZ;
    out.cameraZ = cz;
    final scale = cz == 0 ? 0.0 : cameraDepth / cz;
    out.scale = scale;
    out.x = screenWidth / 2 + scale * cx * screenWidth / 2;
    out.y = screenHeight / 2 - scale * cy * screenHeight / 2;
    out.w = scale * GameConfig.roadWidth * screenWidth / 2;
  }
}

double lerp(double a, double b, double t) => a + (b - a) * t;

double easeIn(double a, double b, double t) => a + (b - a) * t * t;

double easeInOut(double a, double b, double t) =>
    a + (b - a) * ((-math.cos(t * math.pi) / 2) + 0.5);
