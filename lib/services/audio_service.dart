import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

enum Sfx { crash, pickup, whoosh, nitro, levelUp, shield, lane }

extension on Sfx {
  String get file => switch (this) {
        Sfx.crash => 'crash.wav',
        Sfx.pickup => 'pickup.wav',
        Sfx.whoosh => 'whoosh.wav',
        Sfx.nitro => 'nitro.wav',
        Sfx.levelUp => 'levelup.wav',
        Sfx.shield => 'shield.wav',
        Sfx.lane => 'lane.wav',
      };
}

/// Thin wrapper over flame_audio. Every call is guarded so a platform without
/// an audio backend never crashes the game.
class AudioService {
  AudioService(this.enabled);

  final ValueListenable<bool> enabled;

  AudioPlayer? _engine;
  bool _loaded = false;
  double _engineRate = 1;

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'engine.wav',
        for (final s in Sfx.values) s.file,
      ]);
      _loaded = true;
    } catch (e) {
      debugPrint('Audio preload failed: $e');
    }
  }

  void play(Sfx sfx, {double volume = 1}) {
    if (!_loaded || !enabled.value) return;
    _safePlay(sfx.file, volume);
  }

  Future<void> _safePlay(String file, double volume) async {
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (e) {
      debugPrint('Audio play failed: $e');
    }
  }

  Future<void> startEngine() async {
    if (!_loaded || !enabled.value || _engine != null) return;
    try {
      _engine = await FlameAudio.loop('engine.wav', volume: 0.45);
      await _engine?.setPlaybackRate(_engineRate);
    } catch (e) {
      debugPrint('Engine loop failed: $e');
      _engine = null;
    }
  }

  /// Pitches the engine loop with speed; [rate] is roughly 0.7..2.0.
  void setEngineRate(double rate) {
    final clamped = rate.clamp(0.6, 2.2);
    if ((clamped - _engineRate).abs() < 0.02) return;
    _engineRate = clamped;
    _engine?.setPlaybackRate(clamped).ignore();
  }

  Future<void> pauseEngine() async {
    try {
      await _engine?.pause();
    } catch (_) {}
  }

  Future<void> resumeEngine() async {
    if (_engine == null) return startEngine();
    try {
      await _engine?.resume();
    } catch (_) {}
  }

  Future<void> stopEngine() async {
    final p = _engine;
    _engine = null;
    try {
      await p?.stop();
      await p?.dispose();
    } catch (_) {}
  }
}
