import 'dart:math' as math;
import 'dart:ui';

import '../entities/traffic_vehicle.dart';

/// Draws stylised rear-view vehicles with plain canvas primitives, so every
/// car scales crisply at any distance without sprite assets.
class VehiclePainter {
  VehiclePainter._();

  /// Draws a vehicle whose rear bumper sits centred on [bottomCenter] with
  /// the given on-screen [width].
  static void draw(
    Canvas canvas, {
    required Offset bottomCenter,
    required double width,
    required VehicleKind kind,
    required Color color,
    double tilt = 0,
    bool braking = false,
    double lightsAlpha = 0,
    bool isPlayer = false,
    double nitro = 0,
  }) {
    if (width < 1.5) {
      // Far away: a single dot of colour is enough.
      canvas.drawRect(
        Rect.fromCenter(center: bottomCenter, width: width, height: width * 0.6),
        Paint()..color = color,
      );
      return;
    }

    final w = width;
    final h = w * kind.aspect;
    canvas.save();
    canvas.translate(bottomCenter.dx, bottomCenter.dy);
    if (tilt != 0) canvas.rotate(tilt);

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -h * 0.02), width: w * 1.1, height: h * 0.16),
      Paint()..color = const Color(0x55000000),
    );

    // Wheels.
    final wheelW = w * 0.16;
    final wheelH = h * 0.22;
    final wheelPaint = Paint()..color = const Color(0xFF17181C);
    for (final sx in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(sx * (w / 2 - wheelW * 0.45), -wheelH * 0.45),
              width: wheelW,
              height: wheelH),
          Radius.circular(wheelW * 0.3),
        ),
        wheelPaint,
      );
    }

    switch (kind) {
      case VehicleKind.truck:
        _drawTruck(canvas, w, h, color);
      case VehicleKind.bus:
        _drawBus(canvas, w, h, color);
      default:
        _drawCar(canvas, w, h, color, kind, isPlayer: isPlayer);
    }

    _drawLights(canvas, w, h, kind, braking: braking, lightsAlpha: lightsAlpha);

    if (nitro > 0) {
      _drawNitroFlames(canvas, w, h, nitro);
    }
    canvas.restore();
  }

  static Color _shade(Color c, double f) {
    final hsl = HSLColorLite.fromColor(c);
    return hsl.withLightness((hsl.lightness * f).clamp(0.0, 1.0)).toColor();
  }

  static void _drawCar(Canvas canvas, double w, double h, Color color,
      VehicleKind kind, {required bool isPlayer}) {
    final bodyH = h * 0.5;
    final bodyRect = Rect.fromLTWH(-w / 2, -bodyH - h * 0.08, w, bodyH);
    final body = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: Radius.circular(w * 0.12),
      topRight: Radius.circular(w * 0.12),
      bottomLeft: Radius.circular(w * 0.06),
      bottomRight: Radius.circular(w * 0.06),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = Gradient.linear(
          Offset(-w / 2, 0),
          Offset(w / 2, 0),
          [_shade(color, 0.75), color, _shade(color, 0.85)],
          const [0, 0.45, 1],
        ),
    );

    // Cabin / roof with rear window.
    final cabinW = w * (kind == VehicleKind.suv || kind == VehicleKind.van ? 0.9 : 0.72);
    final cabinH = h - bodyH - h * 0.08;
    final cabinTop = -h;
    final cabin = RRect.fromRectAndCorners(
      Rect.fromLTWH(-cabinW / 2, cabinTop, cabinW, cabinH + h * 0.02),
      topLeft: Radius.circular(w * 0.14),
      topRight: Radius.circular(w * 0.14),
    );
    canvas.drawRRect(cabin, Paint()..color = _shade(color, 0.9));
    final glass = RRect.fromRectAndCorners(
      Rect.fromLTWH(-cabinW / 2 + w * 0.05, cabinTop + h * 0.05, cabinW - w * 0.1,
          cabinH * 0.62),
      topLeft: Radius.circular(w * 0.1),
      topRight: Radius.circular(w * 0.1),
      bottomLeft: Radius.circular(w * 0.03),
      bottomRight: Radius.circular(w * 0.03),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, cabinTop),
          Offset(0, cabinTop + cabinH),
          const [Color(0xFF9CC7E8), Color(0xFF243447)],
        ),
    );

    // Bumper and plate.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2 + w * 0.03, -h * 0.2, w - w * 0.06, h * 0.1),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = _shade(color, 0.6),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -h * 0.3), width: w * 0.22, height: h * 0.07),
      Paint()..color = const Color(0xFFE8E8E8),
    );

    if (isPlayer) {
      // Rear spoiler.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.44, -bodyH - h * 0.16, w * 0.88, h * 0.05),
          Radius.circular(w * 0.02),
        ),
        Paint()..color = _shade(color, 0.55),
      );
      for (final sx in [-1, 1]) {
        canvas.drawRect(
          Rect.fromLTWH(sx * w * 0.36 - w * 0.02, -bodyH - h * 0.12, w * 0.04, h * 0.06),
          Paint()..color = _shade(color, 0.55),
        );
      }
    }
  }

  static void _drawTruck(Canvas canvas, double w, double h, Color color) {
    final boxH = h * 0.78;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, -h, w, boxH),
        Radius.circular(w * 0.04),
      ),
      Paint()
        ..shader = Gradient.linear(
          Offset(-w / 2, 0),
          Offset(w / 2, 0),
          [_shade(color, 0.7), _shade(color, 1.05), _shade(color, 0.8)],
        ),
    );
    // Container ribs and rear doors.
    final rib = Paint()
      ..color = _shade(color, 0.6)
      ..strokeWidth = math.max(1, w * 0.015);
    for (var i = 1; i < 6; i++) {
      final x = -w / 2 + w * i / 6;
      canvas.drawLine(Offset(x, -h + h * 0.05), Offset(x, -h + boxH - h * 0.05), rib);
    }
    canvas.drawLine(Offset(0, -h + h * 0.03), Offset(0, -h + boxH - h * 0.03),
        rib..strokeWidth = math.max(1.5, w * 0.03));
    // Chassis.
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.46, -h + boxH, w * 0.92, h * 0.1),
      Paint()..color = const Color(0xFF2B2B30),
    );
  }

  static void _drawBus(Canvas canvas, double w, double h, Color color) {
    final bodyH = h * 0.86;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-w / 2, -h, w, bodyH),
        topLeft: Radius.circular(w * 0.12),
        topRight: Radius.circular(w * 0.12),
        bottomLeft: Radius.circular(w * 0.04),
        bottomRight: Radius.circular(w * 0.04),
      ),
      Paint()
        ..shader = Gradient.linear(
          Offset(-w / 2, 0),
          Offset(w / 2, 0),
          [_shade(color, 0.75), color, _shade(color, 0.85)],
        ),
    );
    // Big rear window and lower window strip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.4, -h + h * 0.08, w * 0.8, h * 0.28),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = const Color(0xFF2E4A63),
    );
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.44, -h + h * 0.42, w * 0.88, h * 0.03),
      Paint()..color = _shade(color, 0.6),
    );
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.46, -h + bodyH - h * 0.05, w * 0.92, h * 0.06),
      Paint()..color = const Color(0xFF2B2B30),
    );
  }

  static void _drawLights(Canvas canvas, double w, double h, VehicleKind kind,
      {required bool braking, required double lightsAlpha}) {
    final y = switch (kind) {
      VehicleKind.truck => -h * 0.28,
      VehicleKind.bus => -h * 0.2,
      _ => -h * 0.46,
    };
    final lw = w * 0.16;
    final lh = h * 0.07;
    final base = braking ? const Color(0xFFFF3B2F) : const Color(0xFFC62828);
    final alpha = braking ? 1.0 : (0.55 + 0.45 * lightsAlpha);
    for (final sx in [-1, 1]) {
      final rect = Rect.fromCenter(
          center: Offset(sx * (w / 2 - lw * 0.7), y), width: lw, height: lh);
      if (braking || lightsAlpha > 0.05) {
        canvas.drawOval(
          rect.inflate(lw * 0.5),
          Paint()
            ..color = base.withValues(alpha: 0.35 * (braking ? 1 : lightsAlpha)),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(lh * 0.4)),
        Paint()..color = base.withValues(alpha: alpha),
      );
    }
  }

  static void _drawNitroFlames(Canvas canvas, double w, double h, double t) {
    final flicker = 0.75 + 0.25 * math.sin(t * 40);
    for (final sx in [-1, 1]) {
      final x = sx * w * 0.22;
      final flameH = h * 0.35 * flicker;
      final path = Path()
        ..moveTo(x - w * 0.06, -h * 0.1)
        ..quadraticBezierTo(x, flameH * 0.3, x, flameH)
        ..quadraticBezierTo(x, flameH * 0.3, x + w * 0.06, -h * 0.1)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = Gradient.linear(
            Offset(x, -h * 0.1),
            Offset(x, flameH),
            const [Color(0xFF9FDBFF), Color(0xFF2E7BFF), Color(0x002E7BFF)],
          ),
      );
    }
  }
}

/// Minimal HSL helper (avoids pulling in the Material `HSLColor` just for
/// shading).
class HSLColorLite {
  HSLColorLite(this.h, this.s, this.lightness, this.a);

  final double h;
  final double s;
  final double lightness;
  final double a;

  factory HSLColorLite.fromColor(Color c) {
    final r = c.r, g = c.g, b = c.b;
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final l = (max + min) / 2;
    var h = 0.0, s = 0.0;
    final d = max - min;
    if (d > 0) {
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h /= 6;
    }
    return HSLColorLite(h, s, l, c.a);
  }

  HSLColorLite withLightness(double l) => HSLColorLite(h, s, l, a);

  Color toColor() {
    double hue2rgb(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    double r, g, b;
    if (s == 0) {
      r = g = b = lightness;
    } else {
      final q = lightness < 0.5
          ? lightness * (1 + s)
          : lightness + s - lightness * s;
      final p = 2 * lightness - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }
    return Color.from(alpha: a, red: r, green: g, blue: b);
  }
}
