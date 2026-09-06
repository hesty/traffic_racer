import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_traffic_rush/services/settings_service.dart';
import 'package:turbo_traffic_rush/services/high_score_service.dart';

void main() {
  group('SettingsService', () {
    test('defaults to sound+music on, tilt off', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = SettingsService();
      await svc.load();
      expect(svc.soundEnabled.value, isTrue);
      expect(svc.musicEnabled.value, isTrue);
      expect(svc.tiltEnabled.value, isFalse);
    });

    test('load respects stored prefs', () async {
      SharedPreferences.setMockInitialValues({
        'sound_enabled': false,
        'music_enabled': false,
        'tilt_enabled': true,
      });
      final svc = SettingsService();
      await svc.load();
      expect(svc.soundEnabled.value, isFalse);
      expect(svc.musicEnabled.value, isFalse);
      expect(svc.tiltEnabled.value, isTrue);
    });

    test('toggleSound flips sound', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = SettingsService();
      await svc.load();
      svc.toggleSound();
      expect(svc.soundEnabled.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sound_enabled'), isFalse);
    });

    test('toggleMusic flips music', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = SettingsService();
      await svc.load();
      svc.toggleMusic();
      expect(svc.musicEnabled.value, isFalse);
    });

    test('toggleTilt flips tilt', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = SettingsService();
      await svc.load();
      svc.toggleTilt();
      expect(svc.tiltEnabled.value, isTrue);
    });

    test('load with corrupt prefs falls back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'sound_enabled': 'not_a_bool',
      });
      final svc = SettingsService();
      await svc.load();
      // Non-bool prefs return null, defaults apply
      expect(svc.soundEnabled.value, isTrue);
    });
  });

  group('HighScoreService', () {
    test('submit records a new high score', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = HighScoreService();
      await svc.load();
      expect(svc.bestScore.value, 0);
      expect(svc.bestDistanceMeters.value, 0);

      final isNew = svc.submit(score: 500, distanceMeters: 100);
      expect(isNew, isTrue);
      expect(svc.bestScore.value, 500);
      expect(svc.bestDistanceMeters.value, 100);
    });

    test('submit does not overwrite when score is lower', () async {
      SharedPreferences.setMockInitialValues({'high_score': 1000, 'best_distance_m': 200});
      final svc = HighScoreService();
      await svc.load();
      expect(svc.bestScore.value, 1000);

      final isNew = svc.submit(score: 500, distanceMeters: 300);
      expect(isNew, isFalse);
      expect(svc.bestScore.value, 1000);
      expect(svc.bestDistanceMeters.value, 300); // distance still updates
    });

    test('submit updates only distance when score is equal', () async {
      SharedPreferences.setMockInitialValues({'high_score': 500});
      final svc = HighScoreService();
      await svc.load();
      final isNew = svc.submit(score: 500, distanceMeters: 150);
      expect(isNew, isFalse);
      expect(svc.bestScore.value, 500);
    });
  });
}
