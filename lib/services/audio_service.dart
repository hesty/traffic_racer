import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

enum Sfx { crash, pickup, whoosh, nitro, levelUp, shield, lane, start, mission, ghost, unlock }

extension on Sfx {
  String get file => switch (this) {
        Sfx.crash => 'crash.wav',
        Sfx.pickup => 'pickup.wav',
        Sfx.whoosh => 'whoosh.wav',
        Sfx.nitro => 'nitro.wav',
        Sfx.levelUp => 'levelup.wav',
        Sfx.shield => 'shield.wav',
        Sfx.lane => 'lane.wav',
        Sfx.start => 'start.wav',
        Sfx.mission => 'mission.wav',
        Sfx.ghost => 'ghost.wav',
        Sfx.unlock => 'unlock.wav',
      };
}

/// Sound effects, engine loop and background music on top of flame_audio.
///
/// Every call is guarded so a platform without an audio backend never crashes
/// the game. The service also reacts to the sound/music toggles: turning a
/// toggle off silences immediately, turning it on restores whatever the game
/// currently wants playing.
class AudioService {
  AudioService({required this.soundEnabled, required this.musicEnabled}) {
    soundEnabled.addListener(_onToggle);
    musicEnabled.addListener(_onToggle);
  }

  static const _engineFile = 'engine.wav';
  static const _musicFile = 'music.wav';

  final ValueListenable<bool> soundEnabled;
  final ValueListenable<bool> musicEnabled;

  AudioPlayer? _engine;
  bool _loaded = false;
  bool _wantsEngine = false;
  bool _wantsMusic = false;
  bool _musicPlaying = false;
  double _engineRate = 1;
  double _engineVolume = 0.4;

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll([
        _engineFile,
        _musicFile,
        for (final s in Sfx.values) s.file,
      ]);
      _loaded = true;
    } catch (e) {
      debugPrint('Audio preload failed: $e');
    }
  }

  void dispose() {
    soundEnabled.removeListener(_onToggle);
    musicEnabled.removeListener(_onToggle);
    stopEngine();
    stopMusic();
  }

  // --- one-shots ---------------------------------------------------------

  void play(Sfx sfx, {double volume = 1}) {
    if (!_loaded || !soundEnabled.value) return;
    _guard(() => FlameAudio.play(sfx.file, volume: volume));
  }

  // --- engine loop -------------------------------------------------------

  Future<void> startEngine() async {
    _wantsEngine = true;
    if (!_loaded || !soundEnabled.value || _engine != null) return;
    await _guard(() async {
      final p = await FlameAudio.loop(_engineFile, volume: _engineVolume);
      await p.setPlaybackRate(_engineRate);
      _engine = p;
    });
  }

  /// Pitches and swells the engine with speed; [speedFraction] is 0..1.3.
  void updateEngine(double speedFraction) {
    final rate = (0.6 + speedFraction * 1.15).clamp(0.5, 2.4);
    final volume = (0.3 + speedFraction * 0.35).clamp(0.2, 0.75);
    if ((rate - _engineRate).abs() > 0.015) {
      _engineRate = rate;
      _guard(() => _engine?.setPlaybackRate(rate));
    }
    if ((volume - _engineVolume).abs() > 0.03) {
      _engineVolume = volume;
      _guard(() => _engine?.setVolume(volume));
    }
  }

  Future<void> pauseEngine() => _guard(() => _engine?.pause());

  Future<void> resumeEngine() async {
    if (_engine == null) return startEngine();
    await _guard(() => _engine?.resume());
  }

  Future<void> stopEngine() async {
    _wantsEngine = false;
    final p = _engine;
    _engine = null;
    await _guard(() async {
      await p?.stop();
      await p?.dispose();
    });
  }

  // --- music -------------------------------------------------------------

  Future<void> startMusic() async {
    _wantsMusic = true;
    if (!_loaded || !musicEnabled.value || _musicPlaying) return;
    _musicPlaying = true;
    await _guard(() => FlameAudio.bgm.play(_musicFile, volume: 0.45));
  }

  Future<void> pauseMusic() => _guard(() => FlameAudio.bgm.pause());

  Future<void> resumeMusic() async {
    if (!_musicPlaying) return startMusic();
    await _guard(() => FlameAudio.bgm.resume());
  }

  Future<void> stopMusic() async {
    _wantsMusic = false;
    if (!_musicPlaying) return;
    _musicPlaying = false;
    await _guard(() => FlameAudio.bgm.stop());
  }

  Future<void> duckMusic(bool duck) =>
      _guard(() => FlameAudio.bgm.audioPlayer.setVolume(duck ? 0.2 : 0.45));

  // --- internals ---------------------------------------------------------

  void _onToggle() {
    if (!soundEnabled.value) {
      final keep = _wantsEngine;
      stopEngine();
      _wantsEngine = keep;
    } else if (_wantsEngine) {
      startEngine();
    }

    if (!musicEnabled.value) {
      final keep = _wantsMusic;
      stopMusic();
      _wantsMusic = keep;
    } else if (_wantsMusic) {
      startMusic();
    }
  }

  Future<void> _guard(Future<void>? Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Audio call failed: $e');
    }
  }
}
