import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/progression/car_catalog.dart';
import 'package:turbo_traffic_rush/progression/garage.dart';
import 'package:turbo_traffic_rush/progression/wallet.dart';

void main() {
  group('Wallet', () {
    test('credits and refuses overspending', () {
      const w = Wallet(100);
      expect(w.credit(50).balance, 150);
      expect(w.spend(100)!.balance, 0);
      expect(w.spend(101), isNull);
    });
  });

  group('CoinFormula', () {
    test('pays for distance, near misses and the ghost', () {
      final base = CoinFormula.forRun(
          distanceMeters: 2000, nearMisses: 10, ghostBeaten: false, streakMultiplier: 1);
      expect(base, (2000 * GameConfig.coinsPerMeter).round() + 10 * GameConfig.coinsPerNearMiss);
      final beaten = CoinFormula.forRun(
          distanceMeters: 2000, nearMisses: 10, ghostBeaten: true, streakMultiplier: 1);
      expect(beaten - base, GameConfig.ghostBeatenBonus);
      final streaked = CoinFormula.forRun(
          distanceMeters: 2000, nearMisses: 10, ghostBeaten: false, streakMultiplier: 1.5);
      expect(streaked, (base * 1.5).round());
    });
  });

  group('Garage', () {
    test('starts with the free default car selected', () {
      final g = Garage.initial();
      expect(g.selectedId, CarCatalog.defaultId);
      expect(g.selectedSkin.price, 0);
      expect(CarCatalog.all.first.id, CarCatalog.defaultId);
    });

    test('buys, selects and refuses what it cannot afford', () {
      final g = Garage.initial();
      final car = CarCatalog.all[1];
      expect(g.buy(car.id, Wallet(car.price - 1)), isNull);
      expect(g.isUnlocked(car.id), isFalse);

      final after = g.buy(car.id, Wallet(car.price + 5));
      expect(after!.balance, 5);
      expect(g.isUnlocked(car.id), isTrue);
      expect(g.selectedId, car.id);

      // Owned cars are not sold twice; unknown ids are ignored.
      expect(g.buy(car.id, const Wallet(9999)), isNull);
      expect(g.buy('nope', const Wallet(9999)), isNull);

      expect(g.select(CarCatalog.all[2].id), isFalse);
      expect(g.select(CarCatalog.defaultId), isTrue);
    });

    test('json keeps a locked selection from sneaking in', () {
      final g = Garage.fromJson({'unlocked': <String>[], 'selected': 'van_pink'});
      expect(g.selectedId, CarCatalog.defaultId);
      final owned = Garage(unlockedIds: {'sedan_blue'}, selectedId: 'sedan_blue');
      final copy = Garage.fromJson(owned.toJson());
      expect(copy.selectedId, 'sedan_blue');
      expect(copy.isUnlocked(CarCatalog.defaultId), isTrue);
    });

    test('catalog ids are unique and priced ascending from free', () {
      final ids = CarCatalog.all.map((c) => c.id).toSet();
      expect(ids.length, CarCatalog.all.length);
      expect(CarCatalog.all.first.price, 0);
      for (var i = 1; i < CarCatalog.all.length; i++) {
        expect(CarCatalog.all[i].price, greaterThanOrEqualTo(CarCatalog.all[i - 1].price));
      }
    });
  });
}
