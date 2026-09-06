import 'dart:math' as math;
import 'dart:ui';

import 'package:turbo_traffic_rush/progression/car_catalog.dart';
import 'package:turbo_traffic_rush/world/vehicle_painter.dart';

/// Draws the app icon: the game's own dusk palette, a one-point-perspective
/// road and the default player car, all with plain canvas primitives so the
/// icon is generated at every size instead of being a scaled bitmap.
///
/// Everything is expressed as a fraction of [s] (the square edge), so the same
/// code renders a crisp 20 px notification icon and the 1024 px store icon.
class AppIconPainter {
  AppIconPainter._();

  // Dusk sky, matching `WorldPalette.dusk` but pushed a little for contrast.
  static const _skyTop = Color(0xFF241452);
  static const _skyMid = Color(0xFF9C3A63);
  static const _skyBottom = Color(0xFFFF9A52);
  static const _sunCore = Color(0xFFFFEFB0);
  static const _sunEdge = Color(0xFFFF6B3D);
  static const _groundNear = Color(0xFF0E1A14);
  static const _groundFar = Color(0xFF23402B);
  static const _roadHaze = Color(0xFF6E5A5A);
  static const _roadNear = Color(0xFF2C2A36);
  static const _rumbleLight = Color(0xFFF0E0D0);
  static const _rumbleDark = Color(0xFFC9402F);
  static const _laneLine = Color(0xFFF5EEDF);

  static const _roadHalfWidthAtBottom = 0.62;
  static const _roadHalfWidthAtHorizon = 0.012;

  // Full-bleed square icon (iOS, and the legacy Android launcher bitmap).
  static const _squareHorizon = 0.42;
  static const _squareCarBottom = 0.94;
  static const _squareCarWidth = 0.55;

  // Android adaptive layers are 108 dp but only the middle 72 dp is ever
  // visible, and a circular mask trims that further. So the scene still bleeds
  // to the layer edge while every landmark — horizon, sun, car — is composed
  // inside that centre window, and the car stays within the 66 dp safe circle.
  static const _adaptiveHorizon = 0.447;
  static const _adaptiveCarBottom = 0.76;
  static const _adaptiveCarWidth = 0.40;

  /// The whole scene, edge to edge and fully opaque.
  static void paintSquare(Canvas canvas, double s) {
    canvas.clipRect(Rect.fromLTWH(0, 0, s, s));
    _paintScene(canvas, s, s * _squareHorizon);
    _paintCar(canvas, s,
        bottomFraction: _squareCarBottom, widthFraction: _squareCarWidth);
    _paintVignette(canvas, s);
  }

  /// Adaptive background layer: everything but the car, so the launcher can
  /// slide the two layers against each other.
  static void paintAdaptiveBackground(Canvas canvas, double s) {
    canvas.clipRect(Rect.fromLTWH(0, 0, s, s));
    _paintScene(canvas, s, s * _adaptiveHorizon);
  }

  /// Adaptive foreground layer: the car alone on a transparent layer.
  static void paintAdaptiveForeground(Canvas canvas, double s) {
    _paintCar(canvas, s,
        bottomFraction: _adaptiveCarBottom, widthFraction: _adaptiveCarWidth);
  }

  /// Themed-icon layer. Android tints this by its alpha, so it is a flat white
  /// silhouette of the same car rather than a colour drawing.
  static void paintAdaptiveMonochrome(Canvas canvas, double s) {
    final w = s * _adaptiveCarWidth;
    final h = w * 0.72; // sedan aspect
    final paint = Paint()..color = const Color(0xFFFFFFFF);

    // One layer, so the window and tail lights can be punched back out of the
    // filled body — a solid blob would not read as a car at launcher size.
    canvas.saveLayer(Rect.fromLTWH(0, 0, s, s), Paint());
    canvas.translate(s / 2, s * _adaptiveCarBottom);

    final wheelW = w * 0.16;
    final wheelH = h * 0.22;
    for (final sx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(sx * (w / 2 - wheelW * 0.45), -wheelH * 0.45),
            width: wheelW,
            height: wheelH,
          ),
          Radius.circular(wheelW * 0.3),
        ),
        paint,
      );
    }

    final bodyH = h * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-w / 2, -bodyH - h * 0.08, w, bodyH),
        topLeft: Radius.circular(w * 0.12),
        topRight: Radius.circular(w * 0.12),
        bottomLeft: Radius.circular(w * 0.06),
        bottomRight: Radius.circular(w * 0.06),
      ),
      paint,
    );

    final cabinW = w * 0.72;
    final cabinH = h - bodyH - h * 0.08;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-cabinW / 2, -h, cabinW, cabinH + h * 0.02),
        topLeft: Radius.circular(w * 0.14),
        topRight: Radius.circular(w * 0.14),
      ),
      paint,
    );

    final cut = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
            -cabinW / 2 + w * 0.06, -h + h * 0.06, cabinW - w * 0.12, cabinH * 0.6),
        topLeft: Radius.circular(w * 0.1),
        topRight: Radius.circular(w * 0.1),
        bottomLeft: Radius.circular(w * 0.03),
        bottomRight: Radius.circular(w * 0.03),
      ),
      cut,
    );
    final lw = w * 0.16;
    final lh = h * 0.07;
    for (final sx in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(sx * (w / 2 - lw * 0.7), -h * 0.46),
            width: lw,
            height: lh,
          ),
          Radius.circular(lh * 0.4),
        ),
        cut,
      );
    }
    canvas.restore();
  }

  static void _paintScene(Canvas canvas, double s, double horizon) {
    _paintSky(canvas, s, horizon);
    _paintGround(canvas, s, horizon);
    _paintRoad(canvas, s, horizon);
  }

  static void _paintSky(Canvas canvas, double s, double horizon) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, horizon),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, horizon),
          const [_skyTop, _skyMid, _skyBottom],
          const [0, 0.58, 1],
        ),
    );

    // Sun sinking into the vanishing point, with a soft halo around it.
    final sunCenter = Offset(s / 2, horizon * 0.99);
    final sunR = s * 0.17;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, s, horizon));
    canvas.drawCircle(
      sunCenter,
      sunR * 2.4,
      Paint()
        ..shader = Gradient.radial(sunCenter, sunR * 2.4, [
          _sunEdge.withValues(alpha: 0.55),
          _sunEdge.withValues(alpha: 0),
        ]),
    );
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, sunCenter.dy - sunR),
          Offset(0, sunCenter.dy + sunR),
          const [_sunCore, _sunEdge],
        ),
    );
    canvas.restore();
  }

  static void _paintGround(Canvas canvas, double s, double horizon) {
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, s, s - horizon),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, horizon),
          Offset(0, s),
          const [_groundFar, _groundNear],
        ),
    );
  }

  /// Half width of the road at screen [y]. A straight road projects to a
  /// trapezoid, so this is linear in screen space.
  static double _halfWidth(double s, double horizon, double y) {
    final u = ((y - horizon) / (s - horizon)).clamp(0.0, 1.0);
    return s * (_roadHalfWidthAtHorizon +
        (_roadHalfWidthAtBottom - _roadHalfWidthAtHorizon) * u);
  }

  static void _paintRoad(Canvas canvas, double s, double horizon) {
    final cx = s / 2;
    final topHalf = _halfWidth(s, horizon, horizon);
    final bottomHalf = _halfWidth(s, horizon, s);

    final road = Path()
      ..moveTo(cx - topHalf, horizon)
      ..lineTo(cx + topHalf, horizon)
      ..lineTo(cx + bottomHalf, s)
      ..lineTo(cx - bottomHalf, s)
      ..close();
    canvas.drawPath(
      road,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, horizon),
          Offset(0, s),
          const [_roadHaze, _roadNear],
          const [0, 0.55],
        ),
    );

    // Depth bands. `u` is the linear screen fraction below the horizon; taking
    // 1/(1 + i * step) spaces the bands evenly in world space instead, so they
    // bunch up towards the vanishing point like the real road does.
    const step = 0.42;
    final bands = <double>[];
    for (var i = 0; ; i++) {
      final u = 1 / (1 + i * step);
      if (u < 0.03) break;
      bands.add(u);
    }

    double yAt(double u) => horizon + (s - horizon) * u;

    for (var i = 0; i + 1 < bands.length; i++) {
      final y0 = yAt(bands[i]);
      final y1 = yAt(bands[i + 1]);
      final h0 = _halfWidth(s, horizon, y0);
      final h1 = _halfWidth(s, horizon, y1);
      final color = i.isEven ? _rumbleDark : _rumbleLight;

      // Rumble strips down both shoulders.
      for (final side in const [-1.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(cx + side * h0, y0)
            ..lineTo(cx + side * h0 * 0.88, y0)
            ..lineTo(cx + side * h1 * 0.88, y1)
            ..lineTo(cx + side * h1, y1)
            ..close(),
          Paint()..color = color,
        );
      }

      // Dashed lane lines on the two inner lane boundaries.
      if (i.isEven) {
        for (final side in const [-1.0, 1.0]) {
          final o0 = h0 / 3;
          final o1 = h1 / 3;
          canvas.drawPath(
            Path()
              ..moveTo(cx + side * (o0 - h0 * 0.022), y0)
              ..lineTo(cx + side * (o0 + h0 * 0.022), y0)
              ..lineTo(cx + side * (o1 + h1 * 0.022), y1)
              ..lineTo(cx + side * (o1 - h1 * 0.022), y1)
              ..close(),
            Paint()..color = _laneLine.withValues(alpha: 0.9),
          );
        }
      }
    }
  }

  static void _paintCar(
    Canvas canvas,
    double s, {
    required double bottomFraction,
    required double widthFraction,
  }) {
    final skin = CarCatalog.byId(CarCatalog.defaultId);
    final bottom = Offset(s / 2, s * bottomFraction);
    final width = s * widthFraction;

    // Warm pool of light under the car so the silhouette lifts off the road.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bottom.dx, bottom.dy - width * 0.05),
        width: width * 2.1,
        height: width * 0.85,
      ),
      Paint()
        ..shader = Gradient.radial(
          Offset(bottom.dx, bottom.dy - width * 0.05),
          width * 1.05,
          [
            const Color(0xFFFF9A52).withValues(alpha: 0.35),
            const Color(0xFFFF9A52).withValues(alpha: 0),
          ],
        ),
    );

    VehiclePainter.draw(
      canvas,
      bottomCenter: bottom,
      width: width,
      kind: skin.kind,
      color: skin.color,
      lightsAlpha: 0.3,
      isPlayer: true,
    );
  }

  static void _paintVignette(Canvas canvas, double s) {
    final center = Offset(s / 2, s * 0.52);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()
        ..shader = Gradient.radial(center, s * math.sqrt1_2, [
          const Color(0x00000000),
          const Color(0x00000000),
          const Color(0x59000000),
        ], const [0, 0.6, 1]),
    );
  }
}
