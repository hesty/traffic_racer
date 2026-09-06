import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/services/store_links.dart';
import 'package:turbo_traffic_rush/services/revenuecat_keys.dart';

void main() {
  test('StoreLinks returns the baked-in default URLs', () {
    expect(StoreLinks.terms, startsWith('https://'));
    expect(StoreLinks.privacy, startsWith('https://'));
  });

  test('RevenueCatKeys.forPlatform returns an empty string on desktop', () {
    // defaultTargetPlatform is TestPlatform in flutter_test
    expect(RevenueCatKeys.forPlatform(), isEmpty);
  });

  test('RevenueCatKeys.android and ios have non-empty default values', () {
    expect(RevenueCatKeys.android, isNotEmpty);
    expect(RevenueCatKeys.ios, isNotEmpty);
  });
}
