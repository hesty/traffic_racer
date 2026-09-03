import 'dart:math' as math;

import '../core/game_config.dart';
import 'day_key.dart';

/// Consecutive calendar days with at least one run.
class Streak {
  const Streak({required this.count, required this.lastDayKey});

  static const none = Streak(count: 0, lastDayKey: 0);

  final int count;
  final int lastDayKey;

  double get coinMultiplier =>
      1 +
      math.min(GameConfig.streakBonusCap,
          GameConfig.streakBonusPerDay * math.max(0, count - 1));

  Map<String, Object?> toJson() => {'count': count, 'lastDay': lastDayKey};

  factory Streak.fromJson(Map<String, Object?> json) => Streak(
        count: json['count'] as int? ?? 0,
        lastDayKey: json['lastDay'] as int? ?? 0,
      );
}

class StreakCalculator {
  StreakCalculator._();

  /// The streak after playing on [now]: unchanged on the same day, one longer
  /// the day after the last play, otherwise back to one.
  static Streak registerPlay(Streak current, DateTime now) {
    final today = dayKeyOf(now);
    if (current.lastDayKey == today) return current;
    final yesterday = dayKeyOf(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)));
    final count = current.lastDayKey == yesterday ? current.count + 1 : 1;
    return Streak(count: count, lastDayKey: today);
  }
}
