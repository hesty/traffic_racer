/// Legal pages the paywall has to link to.
///
/// Both stores require a subscription screen to reach the terms the purchase
/// is made under and the privacy policy; App Review rejects a paywall without
/// them. A `--dart-define` overrides the baked-in default.
abstract final class StoreLinks {

  static const String terms = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://hesty.dev/turbo-traffic-rush/terms',
  );
  static const String privacy = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://hesty.dev/turbo-traffic-rush/privacy',
  );
}
