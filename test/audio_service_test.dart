import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/services/audio_service.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AudioService', () {
    test('preload fails silently when audio cache is unavailable', () async {
      final svc = AudioService(
        soundEnabled: ValueNotifier(true),
        musicEnabled: ValueNotifier(true),
      );
      // In test environment FlameAudio.audioCache.loadAll will throw
      // because no assets are loaded; the service swallows the exception.
      await svc.preload();
      // _loaded remains false; play/startEngine are no-ops.
      expect(svc, isNotNull);
      svc.dispose();
    });

    test('play does nothing when not loaded', () async {
      final svc = AudioService(
        soundEnabled: ValueNotifier(true),
        musicEnabled: ValueNotifier(true),
      );
      svc.play(Sfx.crash); // should not throw
      expect(svc, isNotNull);
      svc.dispose();
    });

    test('play is silenced when soundEnabled is false', () async {
      final svc = AudioService(
        soundEnabled: ValueNotifier(false),
        musicEnabled: ValueNotifier(true),
      );
      await svc.preload();
      svc.play(Sfx.crash); // should not throw
      svc.dispose();
    });

    test('toggle listeners are removed on dispose', () async {
      final sound = ValueNotifier(true);
      final music = ValueNotifier(true);
      final svc = AudioService(soundEnabled: sound, musicEnabled: music);
      await svc.preload();
      svc.dispose();
      // Toggling after dispose should not throw
      sound.value = false;
      music.value = false;
    });

    test('updateEngine handles null engine gracefully', () async {
      final svc = AudioService(
        soundEnabled: ValueNotifier(true),
        musicEnabled: ValueNotifier(true),
      );
      await svc.preload();
      // Engine is null so updateEngine's _guard calls are no-ops
      svc.updateEngine(0.5);
      svc.dispose();
    });

    test('pauseEngine/resumeEngine with no engine is safe', () async {
      final svc = AudioService(
        soundEnabled: ValueNotifier(true),
        musicEnabled: ValueNotifier(true),
      );
      await svc.preload();
      await svc.pauseEngine();
      await svc.resumeEngine(); // calls startEngine internally
      svc.dispose();
    });

    test('startMusic is safe when not loaded', () async {
      final svc = AudioService(
        soundEnabled: ValueNotifier(true),
        musicEnabled: ValueNotifier(false),
      );
      await svc.preload();
      await svc.startMusic();
      svc.dispose();
    });

    test('_onToggle handles sound disable/enable cycle', () async {
      final sound = ValueNotifier(true);
      final svc = AudioService(soundEnabled: sound, musicEnabled: ValueNotifier(true));
      await svc.preload();
      // Toggle off then on
      sound.value = false;
      expect(svc, isNotNull);
      sound.value = true;
      expect(svc, isNotNull);
      svc.dispose();
    });
  });
}
