import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progression/streak.dart';

/// Persists the daily play streak.
class StreakService {
  StreakService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _key = 'streak_v1';

  final DateTime Function() _now;
  final ValueNotifier<Streak> streak = ValueNotifier(Streak.none);
  SharedPreferences? _prefs;

  double get coinMultiplier => streak.value.coinMultiplier;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        streak.value = Streak.fromJson(jsonDecode(raw) as Map<String, Object?>);
      }
    } catch (e) {
      debugPrint('Streak load failed: $e');
    }
  }

  /// Safe to call at every run start; only the first run of a day changes it.
  void registerPlay() {
    final next = StreakCalculator.registerPlay(streak.value, _now());
    if (next == streak.value) return;
    streak.value = next;
    _prefs?.setString(_key, jsonEncode(next.toJson()));
  }
}
