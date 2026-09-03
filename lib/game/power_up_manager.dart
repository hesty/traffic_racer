import 'package:flutter/material.dart';

import '../core/game_config.dart';

enum PowerUpType { shield, doubleScore, slowMotion, nitro }

extension PowerUpTypeInfo on PowerUpType {
  String get label => switch (this) {
        PowerUpType.shield => 'Shield',
        PowerUpType.doubleScore => '2x',
        PowerUpType.slowMotion => 'Slow',
        PowerUpType.nitro => 'Nitro',
      };

  IconData get icon => switch (this) {
        PowerUpType.shield => Icons.shield,
        PowerUpType.doubleScore => Icons.star,
        PowerUpType.slowMotion => Icons.hourglass_bottom,
        PowerUpType.nitro => Icons.bolt,
      };

  Color get color => switch (this) {
        PowerUpType.shield => const Color(0xFF39C0FF),
        PowerUpType.doubleScore => const Color(0xFFFFC93C),
        PowerUpType.slowMotion => const Color(0xFFB57BFF),
        PowerUpType.nitro => const Color(0xFFFF7A29),
      };
}

/// Frame-time based power-up timers. Unlike `dart:async` timers these stop
/// while the game is paused.
class PowerUpManager {
  final Map<PowerUpType, double> _remaining = {};

  bool isActive(PowerUpType type) => (_remaining[type] ?? 0) > 0;
  double remaining(PowerUpType type) => _remaining[type] ?? 0;
  double progress(PowerUpType type) =>
      remaining(type) / GameConfig.powerUpDuration;

  bool get shielded => isActive(PowerUpType.shield);
  double get scoreMultiplier => isActive(PowerUpType.doubleScore) ? 2 : 1;
  double get timeScale =>
      isActive(PowerUpType.slowMotion) ? GameConfig.slowMotionScale : 1;
  double get speedMultiplier =>
      isActive(PowerUpType.nitro) ? GameConfig.nitroMultiplier : 1;

  void activate(PowerUpType type) {
    // Nitro and slow motion are mutually exclusive: the newest wins.
    if (type == PowerUpType.nitro) _remaining.remove(PowerUpType.slowMotion);
    if (type == PowerUpType.slowMotion) _remaining.remove(PowerUpType.nitro);
    _remaining[type] = GameConfig.powerUpDuration;
  }

  /// Advances timers and returns the types that expired this tick.
  List<PowerUpType> tick(double dt) {
    final expired = <PowerUpType>[];
    for (final type in _remaining.keys.toList()) {
      final left = _remaining[type]! - dt;
      if (left <= 0) {
        _remaining.remove(type);
        expired.add(type);
      } else {
        _remaining[type] = left;
      }
    }
    return expired;
  }

  void clear() => _remaining.clear();
}
