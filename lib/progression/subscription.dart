/// Billing period of a Turbo Pass plan.
enum PassPeriod { monthly, annual }

/// One plan on sale, with its price already formatted by the store.
///
/// Pure data on purpose: the paywall renders this, tests build it directly,
/// and nothing in `progression/` knows that a purchase SDK exists.
class SubscriptionOffer {
  const SubscriptionOffer({
    required this.id,
    required this.period,
    required this.priceLabel,
    required this.price,
    this.pricePerMonthLabel,
  });

  /// Package identifier from the store offering (`$rc_monthly`, `$rc_annual`).
  final String id;
  final PassPeriod period;

  /// Store-formatted price for one billing period, e.g. "₺149,99".
  final String priceLabel;

  /// The same price as a number, in the store's currency. Only used to work
  /// out the savings badge, never to display a price.
  final double price;

  /// Store-formatted monthly equivalent; only meaningful for [PassPeriod.annual].
  final String? pricePerMonthLabel;

  String get periodLabel =>
      period == PassPeriod.monthly ? 'PER MONTH' : 'PER YEAR';
}

/// Whole percent the annual plan saves against twelve monthly payments, or
/// null when either plan is missing or the annual one is not actually cheaper.
///
/// Both prices come from the same storefront, so they share a currency and can
/// be compared directly.
int? annualSavingsPercent(List<SubscriptionOffer> offers) {
  double? monthly;
  double? annual;
  for (final offer in offers) {
    if (offer.period == PassPeriod.monthly) monthly = offer.price;
    if (offer.period == PassPeriod.annual) annual = offer.price;
  }
  if (monthly == null || annual == null || monthly <= 0) return null;
  final yearOfMonthly = monthly * 12;
  if (annual >= yearOfMonthly) return null;
  return ((1 - annual / yearOfMonthly) * 100).round();
}
