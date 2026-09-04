import '../core/game_config.dart';

/// Immutable coin balance.
class Wallet {
  const Wallet(this.balance);

  final int balance;

  Wallet credit(int amount) => Wallet(balance + amount);

  /// Returns the wallet after spending, or null when [amount] is not covered.
  Wallet? spend(int amount) =>
      amount > balance ? null : Wallet(balance - amount);
}

/// Coins paid out for a run. Mission rewards are paid separately the moment a
/// mission completes, so they are not part of this formula.
class CoinFormula {
  CoinFormula._();

  static int forRun({
    required int distanceMeters,
    required int nearMisses,
    required double streakMultiplier,
    double passMultiplier = 1,
  }) {
    final base = (distanceMeters * GameConfig.coinsPerMeter).round() +
        nearMisses * GameConfig.coinsPerNearMiss;
    return (base * streakMultiplier * passMultiplier).round();
  }
}
