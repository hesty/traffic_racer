import 'dart:math' as math;
import 'dart:ui';

import 'world_palette.dart';

/// Paints the backdrop above the horizon: gradient sky, sun/moon, stars and
/// two parallax mountain layers that slide with the road's curvature.
class SkyPainter {
  SkyPainter({int seed = 7}) {
    final rng = math.Random(seed);
    _farRidge = _ridge(rng, 28, 0.55);
    _nearRidge = _ridge(rng, 18, 0.9);
    _stars = List.generate(
      90,
      (_) => Offset(rng.nextDouble(), rng.nextDouble() * 0.9),
    );
  }

  late final List<double> _farRidge;
  late final List<double> _nearRidge;
  late final List<Offset> _stars;

  static List<double> _ridge(math.Random rng, int points, double jag) {
    return List.generate(points, (i) {
      final base = math.sin(i * 1.7) * 0.5 + 0.5;
      return (base * 0.6 + rng.nextDouble() * 0.4) * jag;
    });
  }

  void paint(
    Canvas canvas, {
    required Size size,
    required double horizonY,
    required WorldPalette palette,
    required double parallax,
  }) {
    final w = size.width;
    final skyRect = Rect.fromLTWH(0, 0, w, horizonY + 2);

    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, horizonY),
          [palette.skyTop, palette.skyBottom],
        ),
    );

    if (palette.starAlpha > 0.01) {
      final p = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: palette.starAlpha);
      for (final s in _stars) {
        final x = (s.dx * w * 1.4 - parallax * 0.05) % (w * 1.4) - w * 0.2;
        canvas.drawCircle(Offset(x, s.dy * horizonY * 0.8), 1.2, p);
      }
    }

    // Sun / moon with soft glow.
    final sunX = (w * 0.68 - parallax * 0.12) % (w * 1.6) - w * 0.3;
    final sunY = horizonY * 0.42;
    final sunR = w * 0.07;
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR * 2.6,
      Paint()
        ..shader = Gradient.radial(
          Offset(sunX, sunY),
          sunR * 2.6,
          [palette.sun.withValues(alpha: 0.45), palette.sun.withValues(alpha: 0)],
        ),
    );
    canvas.drawCircle(Offset(sunX, sunY), sunR, Paint()..color = palette.sun);

    // Horizon haze.
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY * 0.55, w, horizonY * 0.45 + 2),
      Paint()
        ..shader = Gradient.linear(
          Offset(0, horizonY * 0.55),
          Offset(0, horizonY),
          [palette.horizonGlow.withValues(alpha: 0), palette.horizonGlow],
        ),
    );

    _paintRidge(canvas, _farRidge, w, horizonY, horizonY * 0.28, parallax * 0.18,
        palette.mountainFar);
    _paintRidge(canvas, _nearRidge, w, horizonY, horizonY * 0.16, parallax * 0.35,
        palette.mountainNear);
  }

  void _paintRidge(Canvas canvas, List<double> ridge, double w, double horizonY,
      double amplitude, double offset, Color color) {
    final span = w * 1.5;
    final step = span / (ridge.length - 1);
    final shift = offset % span;
    final path = Path()..moveTo(-span, horizonY + 2);
    for (var rep = -1; rep <= 1; rep++) {
      for (var i = 0; i < ridge.length; i++) {
        final x = rep * span + i * step - shift;
        final y = horizonY - ridge[i] * amplitude;
        path.lineTo(x, y);
      }
    }
    path
      ..lineTo(span * 2, horizonY + 2)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
