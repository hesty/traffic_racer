import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists player preferences and exposes them as listenables.
class SettingsService {
  static const _soundKey = 'sound_enabled';
  static const _musicKey = 'music_enabled';
  static const _tiltKey = 'tilt_enabled';

  final ValueNotifier<bool> soundEnabled = ValueNotifier(true);
  final ValueNotifier<bool> musicEnabled = ValueNotifier(true);
  final ValueNotifier<bool> tiltEnabled = ValueNotifier(false);

  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      soundEnabled.value = _prefs!.getBool(_soundKey) ?? true;
      musicEnabled.value = _prefs!.getBool(_musicKey) ?? true;
      tiltEnabled.value = _prefs!.getBool(_tiltKey) ?? false;
    } catch (_) {
      // Preferences are a convenience; defaults are fine if storage fails.
    }
  }

  void toggleSound() => _set(soundEnabled, _soundKey, !soundEnabled.value);
  void toggleMusic() => _set(musicEnabled, _musicKey, !musicEnabled.value);
  void toggleTilt() => _set(tiltEnabled, _tiltKey, !tiltEnabled.value);

  void _set(ValueNotifier<bool> notifier, String key, bool value) {
    notifier.value = value;
    _prefs?.setBool(key, value);
  }
}
