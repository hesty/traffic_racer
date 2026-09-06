import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/progression/subscription.dart';
import 'package:turbo_traffic_rush/progression/wallet.dart';

void main() {
  group('Wallet', () {
    test('credit adds coins', () {
      final w = Wallet(100).credit(50);
      expect(w.balance, 150);
    });

    test('spend returns null when balance is insufficient', () {
      final w = Wallet(30);
      expect(w.spend(100), isNull);
      expect(w.balance, 30); // original unchanged
    });

    test('spend deducts coins when balance covers amount', () {
      final w = Wallet(100).spend(40)!;
      expect(w.balance, 60);
    });
  });

  group('CoinFormula', () {
    test('forRun calculates base distance coins', () {
      // distanceMeters * coinsPerMeter (0.05) rounded + nearMisses * 2
      final result = CoinFormula.forRun(
        distanceMeters: 100,
        nearMisses: 2,
        streakMultiplier: 1,
      );
      // 100 * 0.05 = 5.0 -> round = 5, + 2*2 = 4, total = 9
      expect(result, 9);
    });

    test('forRun applies passMultiplier', () {
      final result = CoinFormula.forRun(
        distanceMeters: 100,
        nearMisses: 0,
        streakMultiplier: 1,
        passMultiplier: 2,
      );
      // 100 * 0.05 = 5, * 2 pass = 10
      expect(result, 10);
    });
  });

  group('SubscriptionOffer', () {
    test('periodLabel for monthly', () {
      final offer = SubscriptionOffer(
        id: 'monthly',
        period: PassPeriod.monthly,
        priceLabel: '₺99',
        price: 99,
      );
      expect(offer.periodLabel, equals('PER MONTH'));
    });

    test('periodLabel for annual', () {
      final offer = SubscriptionOffer(
        id: 'annual',
        period: PassPeriod.annual,
        priceLabel: '₺999',
        price: 999,
        pricePerMonthLabel: '₺83,25',
      );
      expect(offer.periodLabel, equals('PER YEAR'));
    });
  });

  group('annualSavingsPercent', () {
    test('null when only one plan is present', () {
      final offers = [
        SubscriptionOffer(id: 'm', period: PassPeriod.monthly, priceLabel: '₺100', price: 100),
      ];
      expect(annualSavingsPercent(offers), isNull);
    });

    test('null when annual is not cheaper', () {
      final offers = [
        SubscriptionOffer(id: 'm', period: PassPeriod.monthly, priceLabel: '₺100', price: 100),
        SubscriptionOffer(id: 'a', period: PassPeriod.annual, priceLabel: '₺1300', price: 1300),
      ];
      // 1300 >= 100 * 12 = 1200, so null
      expect(annualSavingsPercent(offers), isNull);
    });

    test('returns savings percentage when annual is cheaper', () {
      final offers = [
        SubscriptionOffer(id: 'm', period: PassPeriod.monthly, priceLabel: '₺100', price: 100),
        SubscriptionOffer(id: 'a', period: PassPeriod.annual, priceLabel: '₺1000', price: 1000),
      ];
      // 100 * 12 = 1200, savings = 200/1200 = 16.67% -> round = 17
      expect(annualSavingsPercent(offers), 17);
    });

    test('null when monthly price is zero', () {
      final offers = [
        SubscriptionOffer(id: 'm', period: PassPeriod.monthly, priceLabel: '₺0', price: 0),
        SubscriptionOffer(id: 'a', period: PassPeriod.annual, priceLabel: '₺500', price: 500),
      ];
      expect(annualSavingsPercent(offers), isNull);
    });
  });
}
