import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_traffic_rush/core/game_config.dart';
import 'package:turbo_traffic_rush/progression/car_catalog.dart';
import 'package:turbo_traffic_rush/progression/garage.dart';
import 'package:turbo_traffic_rush/progression/subscription.dart';
import 'package:turbo_traffic_rush/progression/wallet.dart';
import 'package:turbo_traffic_rush/services/garage_service.dart';
import 'package:turbo_traffic_rush/services/paywall_prompt_service.dart';

/// The Turbo Pass rules that do not need a store: what the pass lends, what
/// happens when it lapses, and when the paywall is allowed to show itself.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const monthly = SubscriptionOffer(
    id: r'$rc_monthly',
    period: PassPeriod.monthly,
    priceLabel: '149,99 TL',
    price: 149.99,
  );
  const annual = SubscriptionOffer(
    id: r'$rc_annual',
    period: PassPeriod.annual,
    priceLabel: '999,99 TL',
    price: 999.99,
    pricePerMonthLabel: '83,33 TL',
  );

  group('annualSavingsPercent', () {
    test('compares the annual plan with twelve monthly payments', () {
      expect(annualSavingsPercent([monthly, annual]), 44);
    });

    test('stays null without both plans, or without an actual saving', () {
      expect(annualSavingsPercent(const []), isNull);
      expect(annualSavingsPercent([monthly]), isNull);
      expect(annualSavingsPercent([annual]), isNull);
      const pricey = SubscriptionOffer(
        id: r'$rc_annual',
        period: PassPeriod.annual,
        priceLabel: '2.000 TL',
        price: 2000,
      );
      expect(annualSavingsPercent([monthly, pricey]), isNull);
    });
  });

  group('CoinFormula', () {
    test('the pass multiplies a run on top of the streak', () {
      final plain = CoinFormula.forRun(
          distanceMeters: 2000,
          nearMisses: 10,
          streakMultiplier: 1);
      final withPass = CoinFormula.forRun(
          distanceMeters: 2000,
          nearMisses: 10,
          streakMultiplier: 1,
          passMultiplier: 2);
      expect(withPass, plain * 2);
    });
  });

  group('pass-only cars', () {
    final premium = CarCatalog.premium.first;

    test('the catalogue actually ships some', () {
      expect(CarCatalog.premium, isNotEmpty);
      expect(CarCatalog.premium.every((c) => c.premium), isTrue);
    });

    test('coins never buy them, however rich the player is', () {
      final g = Garage.initial();
      expect(g.buy(premium.id, const Wallet(999999)), isNull);
      expect(g.isUnlocked(premium.id), isFalse);
    });

    test('the pass decides whether they can be driven', () {
      final g = Garage.initial();
      expect(g.canDrive(premium.id, passActive: false), isFalse);
      expect(g.select(premium.id, passActive: false), isFalse);
      expect(g.canDrive(premium.id, passActive: true), isTrue);
      expect(g.select(premium.id, passActive: true), isTrue);
      expect(g.selectedId, premium.id);
    });

    test('a lapsed pass puts the default car back on the road', () {
      final g = Garage.initial();
      g.select(premium.id, passActive: true);
      expect(g.dropUndrivable(passActive: true), isFalse);
      expect(g.dropUndrivable(passActive: false), isTrue);
      expect(g.selectedId, CarCatalog.defaultId);
    });

    test('a saved pass selection survives the load that precedes the store', () {
      final saved = Garage(unlockedIds: const {}, selectedId: premium.id);
      final copy = Garage.fromJson(saved.toJson());
      expect(copy.selectedId, premium.id);
      expect(copy.dropUndrivable(passActive: false), isTrue);
    });
  });

  group('GarageService', () {
    test('lends the pass cars only while the pass is active', () async {
      var passActive = false;
      final service = GarageService(passActive: () => passActive);
      await service.load();
      final premium = CarCatalog.premium.first;

      expect(service.canDrive(premium.id), isFalse);
      expect(service.select(premium.id), isFalse);
      expect(service.buy(premium.id), isFalse);

      passActive = true;
      service.onPassChanged();
      expect(service.canDrive(premium.id), isTrue);
      expect(service.select(premium.id), isTrue);
      expect(service.selectedSkin.id, premium.id);

      passActive = false;
      service.onPassChanged();
      expect(service.selectedSkin.id, CarCatalog.defaultId);
    });
  });

  group('PaywallPromptService', () {
    test('prompts exactly once, on the configured run', () async {
      final prompt = PaywallPromptService();
      await prompt.load();
      for (var i = 1; i < GameConfig.paywallAutoPromptAfterRuns; i++) {
        expect(prompt.onRunFinished(passActive: false), isFalse);
      }
      expect(prompt.onRunFinished(passActive: false), isTrue);
      expect(prompt.onRunFinished(passActive: false), isFalse);
    });

    test('never prompts a pass holder, but still counts their runs', () async {
      final prompt = PaywallPromptService();
      await prompt.load();
      const runs = GameConfig.paywallAutoPromptAfterRuns + 2;
      for (var i = 0; i < runs; i++) {
        expect(prompt.onRunFinished(passActive: true), isFalse);
      }
      expect(prompt.runsCompleted, runs);
    });

    test('remembers across a reload that it already showed', () async {
      final first = PaywallPromptService();
      await first.load();
      for (var i = 0; i < GameConfig.paywallAutoPromptAfterRuns; i++) {
        first.onRunFinished(passActive: false);
      }
      expect(first.autoShown, isTrue);

      final second = PaywallPromptService();
      await second.load();
      expect(second.runsCompleted, GameConfig.paywallAutoPromptAfterRuns);
      expect(second.onRunFinished(passActive: false), isFalse);
    });
  });
}
