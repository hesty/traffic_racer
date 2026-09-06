import 'package:flutter/foundation.dart';

/// Public RevenueCat SDK keys, one per store.
///
/// These are *public* keys: they ship inside the binary by design and are safe
/// to commit. The API v2 secret key is a dashboard-only credential and never
/// appears in the app.
///
/// A `--dart-define` wins over the baked-in default, which is how a build can
/// point at a different RevenueCat project without a code change:
///
/// ```
/// flutter build ios --release --dart-define=RC_IOS_KEY=appl_xxx
/// ```
abstract final class RevenueCatKeys {

  // RevenueCat project "Turbo Traffic Rush" (proj66719fea). An empty key keeps
  // the pass offline (see [PurchaseService]), so the game still runs on a
  // platform that has no store.
  static const String android = String.fromEnvironment(
    'RC_ANDROID_KEY',
    defaultValue: 'goog_GgXXkCQsJUNYYbgeagEbIPvNOcT',
  );
  static const String ios = String.fromEnvironment(
    'RC_IOS_KEY',
    defaultValue: 'appl_LFVuWslWdnmydUiVIAEDrqwUIkt',
  );

  /// The key for the store this build targets, or an empty string where there
  /// is no store at all (desktop, web, tests).
  static String forPlatform() {
    if (kIsWeb) return '';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => '',
    };
  }
}
