import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_config.dart';
import '../progression/subscription.dart';
import 'revenuecat_keys.dart';

/// The Turbo Pass entitlement and the plans on sale, wrapped around RevenueCat.
///
/// Like every other service here it swallows platform failures: with no store
/// reachable — desktop, tests, an unconfigured key, a first launch offline —
/// the pass reads as inactive, [offers] stays empty and the paywall still lays
/// out. One notifier because a purchase moves several fields at once.
class PurchaseService extends ChangeNotifier {
  static const _key = 'pass_active_v1';

  final Map<String, Package> _packages = {};
  List<SubscriptionOffer> _offers = const [];
  bool _isActive = false;
  bool _storeReady = false;
  bool _busy = false;
  String? _lastError;
  SharedPreferences? _prefs;

  /// Whether the pass is active. Seeded from the last known state so that a
  /// launch without a network does not take the player's cars away.
  bool get isActive => _isActive;

  /// True once RevenueCat is configured; false leaves the paywall in its
  /// "store unavailable" state.
  bool get storeReady => _storeReady;

  /// A purchase or restore is in flight.
  bool get busy => _busy;

  /// Message for the last failed purchase, or null. Cancelling is not a
  /// failure and leaves this null.
  String? get lastError => _lastError;

  /// Plans on sale, monthly first. Empty without a store.
  List<SubscriptionOffer> get offers => _offers;

  /// Savings badge for the annual plan, or null when it cannot be worked out.
  int? get annualSavings => annualSavingsPercent(_offers);

  /// Coin multiplier the pass currently grants.
  double get coinMultiplier => _isActive ? GameConfig.passCoinMultiplier : 1;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isActive = _prefs!.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('Pass load failed: $e');
    }
    await _configure();
  }

  Future<void> _configure() async {
    final apiKey = RevenueCatKeys.forPlatform();
    if (apiKey.isEmpty) {
      debugPrint('No RevenueCat key for this platform; Turbo Pass is offline.');
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      _storeReady = true;
      await refresh();
    } catch (e) {
      debugPrint('RevenueCat configure failed: $e');
    }
  }

  /// Re-reads the entitlement and the current offering.
  Future<void> refresh() async {
    if (!_storeReady) return;
    try {
      _applyCustomerInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('Pass status refresh failed: $e');
    }
    try {
      _readOffering(await Purchases.getOfferings());
      notifyListeners();
    } catch (e) {
      debugPrint('Pass offerings refresh failed: $e');
    }
  }

  /// Buys the plan with [offerId]. Returns whether the pass is active
  /// afterwards; a cancelled purchase returns false and reports no error.
  Future<bool> purchase(String offerId) async {
    final package = _packages[offerId];
    if (_busy || package == null) return false;
    _setBusy(true);
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _applyCustomerInfo(result.customerInfo);
    } on PlatformException catch (e) {
      final code = _codeOf(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = _messageFor(code);
        debugPrint('Purchase failed ($code): ${e.message}');
      }
    } catch (e) {
      _lastError = _genericFailure;
      debugPrint('Purchase failed: $e');
    } finally {
      _setBusy(false);
    }
    return _isActive;
  }

  /// Restores a pass bought on another device or before a reinstall.
  Future<bool> restore() async {
    if (_busy || !_storeReady) return false;
    _setBusy(true);
    try {
      _applyCustomerInfo(await Purchases.restorePurchases());
      if (!_isActive) _lastError = 'No active Turbo Pass on this account.';
    } on PlatformException catch (e) {
      _lastError = _messageFor(_codeOf(e));
      debugPrint('Restore failed: $e');
    } catch (e) {
      _lastError = _genericFailure;
      debugPrint('Restore failed: $e');
    } finally {
      _setBusy(false);
    }
    return _isActive;
  }

  /// Test seam: the overlay layout test needs the paywall in its fullest
  /// state, which otherwise only a real store can produce.
  @visibleForTesting
  void debugSetOffers(List<SubscriptionOffer> offers) {
    _offers = offers;
    notifyListeners();
  }

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final active =
        info.entitlements.active.containsKey(GameConfig.passEntitlement);
    if (active == _isActive) return;
    _isActive = active;
    _prefs?.setBool(_key, active);
    notifyListeners();
  }

  /// Keeps only the two plans the paywall sells, monthly first.
  void _readOffering(Offerings offerings) {
    _packages.clear();
    final current = offerings.current;
    if (current == null) {
      _offers = const [];
      return;
    }
    final offers = <SubscriptionOffer>[];
    for (final package in current.availablePackages) {
      final period = switch (package.packageType) {
        PackageType.monthly => PassPeriod.monthly,
        PackageType.annual => PassPeriod.annual,
        _ => null,
      };
      if (period == null) continue;
      final product = package.storeProduct;
      _packages[package.identifier] = package;
      offers.add(SubscriptionOffer(
        id: package.identifier,
        period: period,
        priceLabel: product.priceString,
        price: product.price,
        pricePerMonthLabel: product.pricePerMonthString,
      ));
    }
    offers.sort((a, b) => a.period.index.compareTo(b.period.index));
    _offers = offers;
  }

  void _setBusy(bool value) {
    _busy = value;
    if (value) _lastError = null;
    notifyListeners();
  }

  static const _genericFailure = 'Something went wrong. Please try again.';

  /// [PurchasesErrorHelper.getErrorCode] parses the platform code as a number
  /// and throws on anything else, so it needs a guard of its own.
  static PurchasesErrorCode _codeOf(PlatformException e) {
    try {
      return PurchasesErrorHelper.getErrorCode(e);
    } catch (_) {
      return PurchasesErrorCode.unknownError;
    }
  }

  static String _messageFor(PurchasesErrorCode code) => switch (code) {
        PurchasesErrorCode.purchaseNotAllowedError =>
          'Purchases are not allowed on this device.',
        PurchasesErrorCode.paymentPendingError =>
          'Payment is pending approval.',
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError =>
          'No connection. Check your network and try again.',
        PurchasesErrorCode.productAlreadyPurchasedError =>
          'You already own this — try Restore Purchases.',
        PurchasesErrorCode.productNotAvailableForPurchaseError ||
        PurchasesErrorCode.storeProblemError =>
          'The store is unavailable right now.',
        _ => _genericFailure,
      };

  @override
  void dispose() {
    if (_storeReady) {
      Purchases.removeCustomerInfoUpdateListener(_applyCustomerInfo);
    }
    super.dispose();
  }
}
