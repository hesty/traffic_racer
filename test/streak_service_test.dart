import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_traffic_rush/progression/streak.dart';
import 'package:turbo_traffic_rush/services/streak_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('load restores a saved streak', () async {
    SharedPreferences.setMockInitialValues({
      'streak_v1': jsonEncode({'count': 4, 'lastDay': 99}),
    });
    final service = StreakService();
    await service.load();
    expect(service.streak.value.count, 4);
    expect(service.coinMultiplier, Streak(count: 4, lastDayKey: 99).coinMultiplier);
  });

  test('registerPlay persists a new day and skips unchanged days', () async {
    final today = DateTime(2026, 9, 6, 12);
    final service = StreakService(now: () => today);
    await service.load();
    expect(service.streak.value, Streak.none);

    service.registerPlay();
    expect(service.streak.value.count, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('streak_v1'), isNotNull);

    service.registerPlay();
    expect(service.streak.value.count, 1, reason: 'same day must not double');
  });

  test('registerPlay before load only updates memory', () async {
    final service = StreakService(now: () => DateTime(2026, 9, 6));
    service.registerPlay();
    expect(service.streak.value.count, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('streak_v1'), isNull);
  });

  test('corrupt stored json falls back to no streak', () async {
    SharedPreferences.setMockInitialValues({'streak_v1': '{not json'});
    final service = StreakService();
    await service.load();
    expect(service.streak.value, Streak.none);
  });
}
