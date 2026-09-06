import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/services/store_links.dart';
import 'package:turbo_traffic_rush/services/revenuecat_keys.dart';

void main() {
  test('StoreLinks returns the baked-in default URLs', () {
    expect(StoreLinks.terms, startsWith('https://'));
    expect(StoreLinks.privacy, startsWith('https://'));
  });

  test('RevenueCatKeys.forPlatform returns android key in test env', () {
    // flutter_test runs on TargetPlatform.android by default
    expect(RevenueCatKeys.forPlatform(), equals(RevenueCatKeys.android));
  });

  test('RevenueCatKeys.android and ios have non-empty default values', () {
    expect(RevenueCatKeys.android, isNotEmpty);
    expect(RevenueCatKeys.ios, isNotEmpty);
  });
}
