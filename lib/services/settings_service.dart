import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists player preferences and exposes them as listenables.
class SettingsService {
  static const _soundKey = 'sound_enabled';
  static const _tiltKey = 'tilt_enabled';

  final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  final ValueNotifier<bool> tiltEnabled = ValueNotifier(false);

  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      soundEnabled.value = _prefs!.getBool(_soundKey) ?? true;
      tiltEnabled.value = _prefs!.getBool(_tiltKey) ?? false;
    } catch (_) {
      // Preferences are a convenience; defaults are fine if storage fails.
    }
  }

  void setSound(bool value) {
    soundEnabled.value = value;
    _prefs?.setBool(_soundKey, value);
  }

  void setTilt(bool value) {
    tiltEnabled.value = value;
    _prefs?.setBool(_tiltKey, value);
  }
}
