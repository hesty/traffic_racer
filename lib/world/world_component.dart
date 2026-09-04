import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection, TextAlign, FontWeight, Shadow;

import '../core/game_config.dart';
import '../core/projection.dart';
import '../core/track.dart';
import '../entities/power_up_pickup.dart';
import '../entities/traffic_vehicle.dart';
import '../game/power_up_manager.dart';
import '../game/traffic_racer_game.dart';
import 'sky_painter.dart';
import 'vehicle_painter.dart';
import 'world_palette.dart';

/// Renders the whole pseudo-3D scene in one pass: sky, road segments,
/// depth-sorted traffic and pickups, the player car and screen effects.
class WorldComponent extends Component with HasGameReference<TrafficRacerGame> {
  /// How much the camera slides sideways with the player (0 = fixed centre,
  /// 1 = car always centred).
  static const double cameraFollow = 0.7;

  final SkyPainter _sky = SkyPainter();
  final math.Random _rng = math.Random();
  int _frame = 0;

  /// Screen x of the player's car from the last frame (for effects).
  double playerScreenX = 0;

  final Paint _fill = Paint();

  @override
  void render(Canvas canvas) {
    final game = this.game;
    final size = game.size;
    final w = size.x, h = size.y;
    final projector = game.projector;
    final track = game.track;
    final palette = WorldPalette.at(game.dayPhase);
    final horizonY = h / 2;

    canvas.save();
    if (game.shake > 0) {
      canvas.translate(
        (_rng.nextDouble() - 0.5) * game.shake * 2,
        (_rng.nextDouble() - 0.5) * game.shake * 2,
      );
    }

    _sky.paint(canvas, size: Size(w, h), horizonY: horizonY, palette: palette,
        parallax: game.skyOffset);
    canvas.drawRect(Rect.fromLTWH(0, horizonY, w, h - horizonY),
        _fill..color = palette.grassDark);

    final cameraX = game.player.offset * GameConfig.roadWidth * cameraFollow;
    final playerZWorld = game.position + projector.playerZ;
    final cameraY = track.heightAt(playerZWorld) + GameConfig.cameraHeight;

    _renderRoad(canvas, track, projector, palette,
        cameraX: cameraX, cameraY: cameraY, w: w, h: h);
    _renderSprites(canvas, track, palette, projector, w, h, cameraX);
    _renderScreenEffects(canvas, w, h, palette);
    canvas.restore();
    _renderFloatingTexts(canvas, w, h);
  }

  // ---------------------------------------------------------------------
  // Road
  // ---------------------------------------------------------------------

  void _renderRoad(Canvas canvas, Track track, Projector projector,
      WorldPalette palette,
      {required double cameraX,
      required double cameraY,
      required double w,
      required double h}) {
    final game = this.game;
    final base = track.segmentAt(game.position);
    final basePercent =
        (track.wrap(game.position) - base.z1) / GameConfig.segmentLength;
    var x = 0.0;
    var dx = -(base.curve * basePercent);
    var maxY = h;
    _frame++;

    for (var n = 0; n < GameConfig.drawDistance; n++) {
      final seg = track.segments[(base.index + n) % track.count];
      final looped = seg.index < base.index;
      final zOffset = looped ? track.length : 0.0;

      projector.project(seg.p1,
          worldX: x, worldY: seg.y1, worldZ: seg.z1 + zOffset,
          cameraX: cameraX, cameraY: cameraY, cameraZ: game.position);
      projector.project(seg.p2,
          worldX: x + dx, worldY: seg.y2, worldZ: seg.z2 + zOffset,
          cameraX: cameraX, cameraY: cameraY, cameraZ: game.position);

      x += dx;
      dx += seg.curve;

      seg.clip = maxY;
      seg.frame = -1;
      if (seg.p1.cameraZ <= projector.cameraDepth ||
          seg.p2.y >= seg.p1.y ||
          seg.p2.y >= maxY) {
        continue;
      }
      seg.frame = _frame;
      _drawSegment(canvas, seg, palette, w, n);
      maxY = seg.p2.y;
    }
  }

  void _drawSegment(
      Canvas canvas, Segment seg, WorldPalette palette, double w, int n) {
    final p1 = seg.p1, p2 = seg.p2;
    final dark = seg.isDarkBand;
    final r1 = p1.w * 0.1, r2 = p2.w * 0.1;

    // Grass.
    canvas.drawRect(Rect.fromLTRB(0, p2.y, w, p1.y),
        _fill..color = dark ? palette.grassDark : palette.grassLight);

    // Rumble strips.
    final rumble = dark ? palette.rumbleDark : palette.rumbleLight;
    _quad(canvas, p1.x - p1.w - r1, p1.y, p1.x - p1.w, p1.y, p2.x - p2.w,
        p2.y, p2.x - p2.w - r2, p2.y, rumble);
    _quad(canvas, p1.x + p1.w + r1, p1.y, p1.x + p1.w, p1.y, p2.x + p2.w,
        p2.y, p2.x + p2.w + r2, p2.y, rumble);

    // Road surface.
    _quad(canvas, p1.x - p1.w, p1.y, p1.x + p1.w, p1.y, p2.x + p2.w, p2.y,
        p2.x - p2.w, p2.y, dark ? palette.roadDark : palette.roadLight);

    // Lane markers (dashed).
    if (!dark && p1.w > 6) {
      final lw1 = math.max(1.0, p1.w * 0.02);
      final lw2 = math.max(0.5, p2.w * 0.02);
      for (var lane = 1; lane < GameConfig.laneCount; lane++) {
        final off = -1 + lane * GameConfig.laneWidth;
        final lx1 = p1.x + p1.w * off;
        final lx2 = p2.x + p2.w * off;
        _quad(canvas, lx1 - lw1, p1.y, lx1 + lw1, p1.y, lx2 + lw2, p2.y,
            lx2 - lw2, p2.y, palette.laneLine);
      }
    }
    // Solid edge lines.
    final ew1 = math.max(0.8, p1.w * 0.012);
    final ew2 = math.max(0.4, p2.w * 0.012);
    for (final side in [-1.0, 1.0]) {
      final ex1 = p1.x + p1.w * side * 0.985;
      final ex2 = p2.x + p2.w * side * 0.985;
      _quad(canvas, ex1 - ew1, p1.y, ex1 + ew1, p1.y, ex2 + ew2, p2.y,
          ex2 - ew2, p2.y, palette.laneLine.withValues(alpha: 0.8));
    }

    // Distance fog.
    final d = n / GameConfig.drawDistance;
    final fog = 1 - math.exp(-d * d * 5.5);
    if (fog > 0.02) {
      canvas.drawRect(Rect.fromLTRB(0, p2.y, w, p1.y),
          _fill..color = palette.fog.withValues(alpha: fog));
    }
  }

  void _quad(Canvas canvas, double x1, double y1, double x2, double y2,
      double x3, double y3, double x4, double y4, Color color) {
    final path = Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..lineTo(x4, y4)
      ..close();
    canvas.drawPath(path, _fill..color = color);
  }

  // ---------------------------------------------------------------------
  // Sprites (traffic, pickups, player)
  // ---------------------------------------------------------------------

  void _renderSprites(Canvas canvas, Track track, WorldPalette palette,
      Projector projector, double w, double h, double cameraX) {
    final game = this.game;
    final playerZ = game.playerTrackZ;

    // Anything more than a car length behind the player's bumper has left
    // the picture; drawing it would only paint a huge sprite over the player.
    const behindLimit = -GameConfig.segmentLength * 1.2;

    final items = <_SpriteRef>[];
    for (final v in game.traffic.vehicles) {
      final seg = track.segmentAt(v.z);
      if (seg.frame != _frame) continue;
      final rel = track.signedDistance(playerZ, v.z);
      if (rel < behindLimit) continue;
      items.add(_SpriteRef(rel, vehicle: v, seg: seg));
    }
    for (final p in game.pickups) {
      final seg = track.segmentAt(p.z);
      if (seg.frame != _frame) continue;
      items.add(_SpriteRef(track.signedDistance(playerZ, p.z), pickup: p, seg: seg));
    }
    items.sort((a, b) => b.rel.compareTo(a.rel));

    // Behind the menu and result screens the road is just a backdrop.
    var playerDrawn =
        game.phase == GamePhase.menu || game.phase == GamePhase.gameOver;
    for (final item in items) {
      if (!playerDrawn && item.rel < 0) {
        _drawPlayer(canvas, w, h, cameraX, palette);
        playerDrawn = true;
      }
      _drawSprite(canvas, item, track, palette, w, h);
    }
    if (!playerDrawn) _drawPlayer(canvas, w, h, cameraX, palette);
  }

  void _drawSprite(Canvas canvas, _SpriteRef item, Track track,
      WorldPalette palette, double w, double h) {
    final seg = item.seg;
    final z = item.vehicle?.z ?? item.pickup!.z;
    final t = ((track.wrap(z) - seg.z1) / GameConfig.segmentLength).clamp(0.0, 1.0);
    final scale = lerp(seg.p1.scale, seg.p2.scale, t);
    final baseX = lerp(seg.p1.x, seg.p2.x, t);
    final baseY = lerp(seg.p1.y, seg.p2.y, t);
    final lane = item.vehicle?.lane ?? item.pickup!.lane;
    final sx = baseX +
        scale * GameConfig.laneCenter(lane) * GameConfig.roadWidth * w / 2;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, seg.clip));
    if (item.vehicle != null) {
      final v = item.vehicle!;
      final width = scale *
          GameConfig.vehicleWidth *
          v.kind.widthFactor *
          GameConfig.roadWidth *
          w / 2;
      VehiclePainter.draw(canvas,
          bottomCenter: Offset(sx, baseY),
          width: width,
          kind: v.kind,
          color: v.color,
          braking: v.braking,
          lightsAlpha: palette.headlightAlpha);
    } else {
      _drawPickup(canvas, item.pickup!, Offset(sx, baseY),
          scale * GameConfig.vehicleWidth * GameConfig.roadWidth * w / 2);
    }
    canvas.restore();
  }

  void _drawPickup(Canvas canvas, PowerUpPickup p, Offset base, double width) {
    if (width < 2) return;
    final r = width * 0.32;
    final bob = math.sin(p.age * 5) * r * 0.25;
    final c = Offset(base.dx, base.dy - r * 1.4 - bob);
    final color = p.type.color;
    canvas.drawOval(
      Rect.fromCenter(center: base, width: r * 2, height: r * 0.5),
      _fill..color = const Color(0x44000000),
    );
    canvas.drawCircle(
      c,
      r * 1.8,
      Paint()
        ..shader = Gradient.radial(c, r * 1.8,
            [color.withValues(alpha: 0.5), color.withValues(alpha: 0)]),
    );
    canvas.drawCircle(c, r, _fill..color = color);
    canvas.drawCircle(
        c, r, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, r * 0.12)
          ..color = const Color(0xFFFFFFFF));
    _drawGlyph(canvas, p.type, c, r);
  }

  void _drawGlyph(Canvas canvas, PowerUpType type, Offset c, double r) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * 0.16)
      ..strokeCap = StrokeCap.round;
    switch (type) {
      case PowerUpType.shield:
        final path = Path()
          ..moveTo(c.dx, c.dy - r * 0.55)
          ..lineTo(c.dx + r * 0.45, c.dy - r * 0.3)
          ..quadraticBezierTo(c.dx + r * 0.4, c.dy + r * 0.35, c.dx, c.dy + r * 0.55)
          ..quadraticBezierTo(c.dx - r * 0.4, c.dy + r * 0.35, c.dx - r * 0.45, c.dy - r * 0.3)
          ..close();
        canvas.drawPath(path, paint);
      case PowerUpType.nitro:
        final path = Path()
          ..moveTo(c.dx + r * 0.15, c.dy - r * 0.6)
          ..lineTo(c.dx - r * 0.3, c.dy + r * 0.05)
          ..lineTo(c.dx + r * 0.05, c.dy + r * 0.05)
          ..lineTo(c.dx - r * 0.15, c.dy + r * 0.6)
          ..lineTo(c.dx + r * 0.3, c.dy - r * 0.05)
          ..lineTo(c.dx - r * 0.05, c.dy - r * 0.05)
          ..close();
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
      case PowerUpType.slowMotion:
        canvas.drawCircle(c, r * 0.55, paint);
        canvas.drawLine(c, Offset(c.dx, c.dy - r * 0.4), paint);
        canvas.drawLine(c, Offset(c.dx + r * 0.3, c.dy), paint);
      case PowerUpType.doubleScore:
        final tp = TextPainter(
          text: TextSpan(
            text: '2x',
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: r * 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawPlayer(
      Canvas canvas, double w, double h, double cameraX, WorldPalette palette) {
    final game = this.game;
    final scale = 1 / GameConfig.cameraHeight;
    final width = scale * GameConfig.vehicleWidth * GameConfig.roadWidth * w / 2;
    final sx = w / 2 +
        (game.player.offset * GameConfig.roadWidth - cameraX) * scale * w / 2;
    playerScreenX = sx;
    final bounce = math.sin(game.runTime * 32) * game.speedFraction * 1.4;
    final baseY = h - h * 0.05 + bounce;
    final crashed = game.phase == GamePhase.crashing;

    if (game.powerUps.shielded) {
      final pulse = 0.55 + 0.25 * math.sin(game.runTime * 9);
      final c = Offset(sx, baseY - width * 0.35);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: width * 1.7, height: width * 1.3),
        Paint()
          ..shader = Gradient.radial(c, width * 0.85, [
            PowerUpType.shield.color.withValues(alpha: 0.05),
            PowerUpType.shield.color.withValues(alpha: 0.35 * pulse),
            PowerUpType.shield.color.withValues(alpha: 0),
          ], const [0, 0.85, 1]),
      );
    }

    final skin = game.selectedSkin;
    VehiclePainter.draw(canvas,
        bottomCenter: Offset(sx, baseY),
        width: width * skin.kind.widthFactor,
        kind: skin.kind,
        color: skin.color,
        tilt: crashed ? 0.35 : game.player.steer * 0.07,
        braking: crashed,
        lightsAlpha: palette.headlightAlpha,
        isPlayer: true,
        nitro: game.nitroVisual > 0.05 ? game.runTime * game.nitroVisual : 0);
  }

  // ---------------------------------------------------------------------
  // Effects
  // ---------------------------------------------------------------------

  void _renderScreenEffects(
      Canvas canvas, double w, double h, WorldPalette palette) {
    final game = this.game;

    // Speed lines under nitro or very high speed.
    final lines = math.max(game.nitroVisual, (game.speedFraction - 0.85) * 3)
        .clamp(0.0, 1.0);
    if (lines > 0.02) {
      final paint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 * lines)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final c = Offset(w / 2, h * 0.45);
      for (var i = 0; i < 26; i++) {
        final a = i / 26 * math.pi * 2 + game.runTime * 0.7;
        final jitter = math.sin(game.runTime * 25 + i) * 0.5 + 0.5;
        final r0 = w * (0.45 + 0.15 * jitter);
        final r1 = r0 + w * 0.25 * lines;
        canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * r0,
            c + Offset(math.cos(a), math.sin(a)) * r1, paint);
      }
    }

    // Slow-motion vignette.
    if (game.powerUps.isActive(PowerUpType.slowMotion)) {
      final t = game.powerUps.progress(PowerUpType.slowMotion).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = Gradient.radial(Offset(w / 2, h / 2), w * 0.9, [
            PowerUpType.slowMotion.color.withValues(alpha: 0),
            PowerUpType.slowMotion.color.withValues(alpha: 0.35 * math.min(1, t * 3)),
          ]),
      );
    }

    // Crash flash + debris.
    if (game.phase == GamePhase.crashing) {
      final t = (game.crashTimer / GameConfig.crashDuration).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
          _fill..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6 * t * t));
    }
    for (final d in game.debris) {
      canvas.drawRect(
        Rect.fromCenter(center: d.position, width: d.size, height: d.size),
        _fill..color = d.color.withValues(alpha: d.life.clamp(0.0, 1.0)),
      );
    }
  }

  void _renderFloatingTexts(Canvas canvas, double w, double h) {
    for (final t in game.floatingTexts) {
      final grow = 1 + (1 - t.alpha) * 0.15;
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            color: t.color.withValues(alpha: t.alpha),
            fontSize: t.fontSize * grow,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: const Color(0xFF000000).withValues(alpha: 0.7 * t.alpha),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(t.x * w - tp.width / 2, t.y * h - tp.height / 2));
    }
  }
}

class _SpriteRef {
  _SpriteRef(this.rel, {this.vehicle, this.pickup, required this.seg});

  final double rel;
  final TrafficVehicle? vehicle;
  final PowerUpPickup? pickup;
  final Segment seg;
}
