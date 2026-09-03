import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/game_config.dart';
import '../core/projection.dart';
import '../core/track.dart';
import '../entities/player.dart';
import '../entities/power_up_pickup.dart';
import '../entities/traffic_vehicle.dart';
import '../services/audio_service.dart';
import '../services/high_score_service.dart';
import '../services/settings_service.dart';
import '../services/tilt_controller.dart';
import '../world/effects.dart';
import '../world/world_component.dart';
import 'hud_model.dart';
import 'power_up_manager.dart';
import 'score_keeper.dart';
import 'traffic_manager.dart';

enum GamePhase { menu, playing, paused, crashing, gameOver }

/// Overlay identifiers registered in `main.dart`.
class Overlays {
  Overlays._();
  static const menu = 'menu';
  static const hud = 'hud';
  static const pause = 'pause';
  static const gameOver = 'gameOver';
}

/// Main game: owns the simulation state and drives the pseudo-3D world.
class TrafficRacerGame extends FlameGame with KeyboardEvents {
  TrafficRacerGame({
    required this.settings,
    required this.highScores,
    math.Random? random,
  })  : _rng = random ?? math.Random(),
        audio = AudioService(
          soundEnabled: settings.soundEnabled,
          musicEnabled: settings.musicEnabled,
        );

  final SettingsService settings;
  final HighScoreService highScores;
  final AudioService audio;
  final math.Random _rng;

  final Player player = Player();
  final ScoreKeeper stats = ScoreKeeper();
  final PowerUpManager powerUps = PowerUpManager();
  final HudModel hud = HudModel();
  final List<PowerUpPickup> pickups = [];
  final List<FloatingText> floatingTexts = [];
  final List<Debris> debris = [];

  late Track track;
  late TrafficManager traffic;
  late Projector projector;
  late final WorldComponent scene;

  GamePhase phase = GamePhase.menu;

  /// Camera position along the track (world units).
  double position = 0;

  /// Current forward speed (world units / second).
  double speed = 0;

  /// Accumulated horizontal parallax for the backdrop.
  double skyOffset = 0;

  /// Seconds since the current run started.
  double runTime = 0;

  /// 0..1 progress through the day/night cycle.
  double dayPhase = 0;

  double shake = 0;
  double crashTimer = 0;
  double nitroVisual = 0;
  double _powerUpSpawnTimer = 0;
  double _hudTimer = 0;
  bool isNewRecord = false;

  TiltController? _tilt;

  static const double _unitsPerKmh = 40;
  static const double _unitsPerMeter = 144;
  static const double _dayCycleMeters = 2600;

  double get playerTrackZ => track.wrap(position + projector.playerZ);
  double get speedFraction => (speed / GameConfig.maxSpeed).clamp(0.0, 1.3);
  int get speedKmh => (speed / _unitsPerKmh).round();
  int get distanceMeters => (stats.distance / _unitsPerMeter).round();

  @override
  Color backgroundColor() => const Color(0xFF05071A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    projector = Projector(screenWidth: size.x, screenHeight: size.y);
    track = Track.generate(seed: _rng.nextInt(1 << 30));
    traffic = TrafficManager(track, random: _rng);

    scene = WorldComponent();
    await add(scene);
    await add(_InputLayer());

    // Not awaited: the menu should appear immediately; sounds simply start
    // working once the cache is warm.
    unawaited(audio.preload());
    overlays.add(Overlays.menu);
    if (_autoStartRequested) startRun();
  }

  /// Debug-only QA hook: `flutter run --dart-define=TTR_AUTOSTART=true` skips
  /// the menu so a run can be screenshotted without any input.
  static bool get _autoStartRequested =>
      kDebugMode && const bool.fromEnvironment('TTR_AUTOSTART');

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    projector = Projector(screenWidth: size.x, screenHeight: size.y);
  }

  // ---------------------------------------------------------------------
  // Run lifecycle
  // ---------------------------------------------------------------------

  void startRun() {
    track = Track.generate(seed: _rng.nextInt(1 << 30));
    traffic = TrafficManager(track, random: _rng);
    stats.reset();
    powerUps.clear();
    player.reset();
    pickups.clear();
    floatingTexts.clear();
    debris.clear();
    position = 0;
    speed = GameConfig.baseSpeed * 0.6;
    runTime = 0;
    dayPhase = 0;
    shake = 0;
    nitroVisual = 0;
    isNewRecord = false;
    _powerUpSpawnTimer = GameConfig.powerUpSpawnInterval * 0.5;

    phase = GamePhase.playing;
    overlays.remove(Overlays.menu);
    overlays.remove(Overlays.gameOver);
    overlays.add(Overlays.hud);
    audio.play(Sfx.start);
    audio.startEngine();
    audio.startMusic();
    audio.duckMusic(false);
    _syncTilt();
    _publishHud();
  }

  void pauseRun() {
    if (phase != GamePhase.playing) return;
    phase = GamePhase.paused;
    overlays.add(Overlays.pause);
    audio.pauseEngine();
    audio.pauseMusic();
    _tilt?.stop();
  }

  void resumeRun() {
    if (phase != GamePhase.paused) return;
    phase = GamePhase.playing;
    overlays.remove(Overlays.pause);
    audio.resumeEngine();
    audio.resumeMusic();
    _syncTilt();
  }

  void restartRun() {
    overlays.remove(Overlays.pause);
    audio.stopEngine();
    startRun();
  }

  void backToMenu() {
    phase = GamePhase.menu;
    overlays.remove(Overlays.pause);
    overlays.remove(Overlays.gameOver);
    overlays.remove(Overlays.hud);
    overlays.add(Overlays.menu);
    traffic.clear();
    pickups.clear();
    debris.clear();
    floatingTexts.clear();
    powerUps.clear();
    audio.stopEngine();
    audio.stopMusic();
    _tilt?.stop();
  }

  void _crash() {
    phase = GamePhase.crashing;
    crashTimer = GameConfig.crashDuration;
    shake = 18;
    audio.play(Sfx.crash);
    audio.stopEngine();
    audio.duckMusic(true);
    _tilt?.stop();
    overlays.remove(Overlays.hud);
    _spawnDebris(count: 34);
  }

  void _finishRun() {
    phase = GamePhase.gameOver;
    isNewRecord = highScores.submit(
      score: stats.score,
      distanceMeters: distanceMeters,
    );
    overlays.add(Overlays.gameOver);
  }

  /// Requests a lane change; -1 = left, 1 = right.
  void steer(int direction) {
    if (phase != GamePhase.playing) return;
    if (player.changeLane(direction)) audio.play(Sfx.lane, volume: 0.6);
  }

  void togglePause() {
    if (phase == GamePhase.playing) {
      pauseRun();
    } else if (phase == GamePhase.paused) {
      resumeRun();
    }
  }

  void _syncTilt() {
    if (settings.tiltEnabled.value && phase == GamePhase.playing) {
      _tilt ??= TiltController(onLaneChange: steer);
      _tilt!.start();
    } else {
      _tilt?.stop();
    }
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) pauseRun();
  }

  @override
  void onRemove() {
    _tilt?.stop();
    audio.dispose();
    super.onRemove();
  }

  // ---------------------------------------------------------------------
  // Simulation
  // ---------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    final step = math.min(dt, 1 / 20);
    switch (phase) {
      case GamePhase.menu:
        _updateAttract(step);
      case GamePhase.playing:
        _simulate(step);
      case GamePhase.crashing:
        _updateCrash(step);
      case GamePhase.paused:
      case GamePhase.gameOver:
        break;
    }
    _updateEffects(step);
  }

  void _updateAttract(double dt) {
    speed = GameConfig.baseSpeed * 0.35;
    position = track.wrap(position + speed * dt);
    skyOffset += track.segmentAt(position).curve * dt * 60;
    dayPhase = (dayPhase + dt * 0.004) % 1;
  }

  void _updateCrash(double dt) {
    crashTimer -= dt;
    // The wreck stops almost instantly while traffic keeps flowing past.
    speed = math.max(0, speed - GameConfig.maxSpeed * 4 * dt);
    position = track.wrap(position + speed * dt);
    traffic.update(dt, playerZ: playerTrackZ);
    if (crashTimer <= 0) _finishRun();
  }

  void _simulate(double dt) {
    final expired = powerUps.tick(dt);
    for (final type in expired) {
      _toast(type == PowerUpType.nitro ? 'NITRO OUT' : '${type.label} over',
          type.color.withValues(alpha: 0.8));
    }

    final worldDt = dt * powerUps.timeScale;
    final targetSpeed = math.min(
          GameConfig.maxSpeed,
          GameConfig.baseSpeed + GameConfig.speedPerLevel * (stats.level - 1),
        ) *
        powerUps.speedMultiplier;
    speed += (targetSpeed - speed) * math.min(1, dt * 1.6);
    nitroVisual += ((powerUps.isActive(PowerUpType.nitro) ? 1 : 0) - nitroVisual) *
        math.min(1, dt * 4);

    final dz = speed * worldDt;
    position = track.wrap(position + dz);
    runTime += dt;
    player.update(dt);

    final playerZ = playerTrackZ;
    traffic.update(worldDt, playerZ: playerZ);
    traffic.maintain(
      playerZ: playerZ,
      level: stats.level,
      avoidLane: runTime < GameConfig.startGraceSeconds ? player.lane : null,
    );
    skyOffset += track.segmentAt(position).curve * speedFraction * dt * 90;
    dayPhase = (stats.distance / _unitsPerMeter / _dayCycleMeters) % 1;

    _resolveTraffic(playerZ);
    _updatePickups(dt, playerZ);

    if (stats.addDistance(dz, multiplier: powerUps.scoreMultiplier)) {
      _onLevelUp();
    }
    stats.tick(dt);
    audio.updateEngine(speedFraction);

    _hudTimer -= dt;
    if (_hudTimer <= 0) {
      _hudTimer = 1 / 12;
      _publishHud();
    }
  }

  void _resolveTraffic(double playerZ) {
    final playerHalf = GameConfig.vehicleWidth / 2;
    for (final v in List<TrafficVehicle>.of(traffic.vehicles)) {
      final rel = track.signedDistance(playerZ, v.z);
      final lateral = (GameConfig.laneCenter(v.lane) - player.offset).abs();
      final overlapWidth =
          playerHalf + GameConfig.vehicleWidth * v.kind.widthFactor / 2;

      if (rel.abs() < GameConfig.collisionLength && lateral < overlapWidth * 0.92) {
        if (powerUps.shielded) {
          _smashThrough(v);
        } else {
          _crash();
          return;
        }
        continue;
      }

      final crossedNow = !v.lastRelativeZ.isNaN && v.lastRelativeZ > 0 && rel <= 0;
      v.lastRelativeZ = rel;
      if (crossedNow && !v.passed) {
        v.passed = true;
        stats.registerOvertake();
        final laneGap = (v.lane - player.lane).abs();
        if (laneGap == 1 && lateral < GameConfig.laneWidth * 1.15) {
          _nearMiss(v);
        }
      }
    }
  }

  void _nearMiss(TrafficVehicle v) {
    final bonus = stats.registerNearMiss(multiplier: powerUps.scoreMultiplier);
    audio.play(Sfx.whoosh, volume: 0.8);
    final side = v.lane < player.lane ? 0.28 : 0.72;
    floatingTexts.add(FloatingText(
      text: stats.combo > 1 ? 'NEAR MISS x${stats.combo}  +$bonus' : 'NEAR MISS  +$bonus',
      color: const Color(0xFFFFE066),
      x: side,
      y: 0.62,
      fontSize: stats.combo > 3 ? 26 : 22,
    ));
    _publishHud();
  }

  void _smashThrough(TrafficVehicle v) {
    traffic.vehicles.remove(v);
    stats.score += 60;
    shake = math.max(shake, 8);
    audio.play(Sfx.crash, volume: 0.35);
    _spawnDebris(count: 14, color: v.color);
    _toast('SMASH  +60', PowerUpType.shield.color);
  }

  void _updatePickups(double dt, double playerZ) {
    _powerUpSpawnTimer -= dt;
    if (_powerUpSpawnTimer <= 0) {
      _powerUpSpawnTimer = GameConfig.powerUpSpawnInterval *
          (0.8 + _rng.nextDouble() * 0.5);
      _spawnPickup(playerZ);
    }

    for (final p in List<PowerUpPickup>.of(pickups)) {
      p.age += dt;
      final rel = track.signedDistance(playerZ, p.z);
      if (rel < -GameConfig.despawnBehind) {
        pickups.remove(p);
        continue;
      }
      final lateral = (GameConfig.laneCenter(p.lane) - player.offset).abs();
      if (rel.abs() < GameConfig.collisionLength &&
          lateral < GameConfig.laneWidth * 0.6) {
        pickups.remove(p);
        _collect(p.type);
      }
    }
  }

  void _spawnPickup(double playerZ) {
    final lane = _rng.nextInt(GameConfig.laneCount);
    final z = track.wrap(playerZ +
        GameConfig.minSpawnAhead +
        _rng.nextDouble() * GameConfig.segmentLength * 60);
    // Never drop a pickup on top of traffic.
    for (final v in traffic.vehicles) {
      if (v.lane == lane &&
          track.signedDistance(v.z, z).abs() < GameConfig.segmentLength * 6) {
        return;
      }
    }
    final type = PowerUpType.values[_rng.nextInt(PowerUpType.values.length)];
    pickups.add(PowerUpPickup(type: type, lane: lane, z: z));
  }

  void _collect(PowerUpType type) {
    powerUps.activate(type);
    switch (type) {
      case PowerUpType.nitro:
        audio.play(Sfx.nitro);
      case PowerUpType.shield:
        audio.play(Sfx.shield);
      default:
        audio.play(Sfx.pickup);
    }
    _toast(type.label.toUpperCase(), type.color, size: 28);
    _publishHud();
  }

  void _onLevelUp() {
    audio.play(Sfx.levelUp);
    floatingTexts.add(FloatingText(
      text: 'LEVEL ${stats.level}',
      color: const Color(0xFFFFFFFF),
      x: 0.5,
      y: 0.4,
      life: 1.6,
      fontSize: 40,
    ));
    _publishHud();
  }

  void _toast(String text, Color color, {double size = 22}) {
    floatingTexts.add(FloatingText(
      text: text,
      color: color,
      x: 0.5,
      y: 0.55,
      fontSize: size,
    ));
  }

  void _spawnDebris({required int count, Color color = const Color(0xFFFFC107)}) {
    final origin = Offset(scene.playerScreenX, size.y * 0.9);
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * math.pi * 1.2;
      final v = 250 + _rng.nextDouble() * 500;
      debris.add(Debris(
        position: origin,
        velocity: Offset(math.cos(angle) * v, math.sin(angle) * v),
        color: i.isEven ? color : const Color(0xFFB0BEC5),
        size: 3 + _rng.nextDouble() * 6,
        life: 0.8 + _rng.nextDouble() * 0.8,
      ));
    }
  }

  void _updateEffects(double dt) {
    shake = math.max(0, shake - dt * 30);
    for (final t in floatingTexts) {
      t.update(dt);
    }
    floatingTexts.removeWhere((t) => t.life <= 0);
    for (final d in debris) {
      d.update(dt);
    }
    debris.removeWhere((d) => d.life <= 0);
  }

  void _publishHud() {
    hud.publish(
      score: stats.score,
      level: stats.level,
      speedKmh: speedKmh,
      combo: stats.combo,
      comboProgress: stats.comboActive
          ? stats.comboTimeLeft / GameConfig.comboWindow
          : 0,
      bestScore: highScores.bestScore.value,
      powerUpProgress: {
        for (final t in PowerUpType.values)
          if (powerUps.isActive(t)) t: powerUps.progress(t),
      },
    );
  }

  // ---------------------------------------------------------------------
  // Keyboard (desktop / web / simulator)
  // ---------------------------------------------------------------------

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      steer(-1);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      steer(1);
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyP) {
      togglePause();
    } else if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (phase == GamePhase.menu || phase == GamePhase.gameOver) startRun();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}

/// Full-screen touch layer: swipe or tap either half of the screen to change
/// lanes.
class _InputLayer extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference<TrafficRacerGame> {
  double _dragDx = 0;
  bool _dragConsumed = false;

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragDx = 0;
    _dragConsumed = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragConsumed) return;
    _dragDx += event.localDelta.x;
    final threshold = math.min(size.x * 0.1, 56.0);
    if (_dragDx.abs() >= threshold) {
      game.steer(_dragDx.sign.toInt());
      _dragConsumed = true;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragConsumed = false;
    _dragDx = 0;
  }

  @override
  void onTapUp(TapUpEvent event) {
    // Ignore taps that ended a swipe.
    if (_dragConsumed) return;
    game.steer(event.localPosition.x < size.x / 2 ? -1 : 1);
  }
}
