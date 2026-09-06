import 'dart:math' as math;

import '../core/game_config.dart';
import 'mission.dart';

/// Rolls the day's missions. Deterministic per calendar day, so every device
/// agrees on the goals without a server.
abstract final class MissionCatalog {

  static List<Mission> forDay(int dayKey) {
    final rng = math.Random(dayKey);
    final kinds = List.of(MissionKind.values)..shuffle(rng);
    return [
      for (var i = 0; i < GameConfig.missionsPerDay; i++)
        _roll(rng, kinds[i % kinds.length], id: '$dayKey-$i'),
    ];
  }

  static Mission _roll(math.Random rng, MissionKind kind, {required String id}) {
    final tier = rng.nextInt(GameConfig.missionRewards.length);
    return Mission(
      id: id,
      kind: kind,
      target: kind.targets[tier.clamp(0, kind.targets.length - 1)],
      coinReward: GameConfig.missionRewards[tier],
    );
  }
}
