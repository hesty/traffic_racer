# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Turbo Traffic Rush (package name `turbo_traffic_rush`): a portrait-only, pseudo-3D arcade traffic racer built with Flutter and Flame. Three lanes, swipe/tap/keyboard/tilt lane changes, near-miss combos, power-ups, procedurally generated looping track. Targets Android and iOS (bundle ids `com.hesty.mobile_game` / `com.hesty.racer`). No sprite sheets: the whole world is drawn procedurally with `Canvas` calls; the only image asset in use is `assets/images/car.png` on the menu.

## Commands

```bash
flutter pub get                       # install deps
flutter run                           # run on connected device / simulator
flutter analyze                       # lint (flutter_lints, default rules)
flutter test                          # all tests
flutter test test/track_test.dart     # one file
flutter test --plain-name "road centre projects"   # one test by name
flutter build apk --release / flutter build ios --release
```

Helper scripts (run from `scripts/`):
- `clean_ios.sh` — nukes `ios/Pods` + `Podfile.lock`, then `flutter clean && flutter pub get`. Uses `sudo`.
- `generate_audio.py` — regenerates every WAV in `assets/audio/` procedurally (needs `numpy`). Sound effects are generated, not authored; edit the script rather than the WAVs.
- `check_16_kb.sh <apk|aab|dir>` — checks native libs for Android 16 KB page alignment (Google Play requirement).

Tests are pure Dart unit tests over `core/` and `game/` (no widget tests, no Flame `GameWidget` in tests). They rely on deterministic seeds (`Track.generate(seed:)`, `Random(n)` injected into `TrafficManager`). Note: as of this writing `traffic never blocks every lane on the same stretch` in `test/traffic_manager_test.dart` fails on `main` because `_regulateSpeed` lets vehicles drift into a full-lane block after spawn; treat that as a known pre-existing failure, not something you introduced.

## Architecture

Layers, dependency direction top → bottom (lower layers never import higher ones):

```
main.dart            GameWidget.controlled + overlayBuilderMap (menu/hud/pause/gameOver)
overlays/            Flutter widgets shown over the game; read game state, call game methods
game/                TrafficRacerGame (simulation + phase machine), TrafficManager, ScoreKeeper,
                     PowerUpManager, HudModel
world/               WorldComponent (single Flame Component that renders everything), painters, palette
entities/            plain data classes: Player, TrafficVehicle, PowerUpPickup
services/            AudioService, SettingsService, HighScoreService, TiltController
core/                GameConfig (all tunables), Projector (perspective math), Track/Segment
```

### Simulation model (`game/traffic_racer_game.dart`)
- `TrafficRacerGame` is a `FlameGame` but almost nothing is a Flame component. Entities are plain lists (`traffic.vehicles`, `pickups`, `floatingTexts`, `debris`) mutated in `update()`. Only two components are added: `WorldComponent` (render) and `_InputLayer` (touch).
- `GamePhase` (`menu, playing, paused, crashing, gameOver`) drives `update()`. Overlay add/remove happens only inside the lifecycle methods (`startRun`, `pauseRun`, `resumeRun`, `backToMenu`, `_crash`, `_finishRun`). Keep overlay bookkeeping there; overlays themselves just call these.
- `update()` clamps `dt` to 1/20 s. Power-ups and combos use frame-time timers (`PowerUpManager.tick`, `ScoreKeeper.tick`), never `dart:async` timers, so pausing freezes them for free.
- Slow-motion works by scaling `worldDt` (traffic + position) while UI/effect timers still use raw `dt`.
- HUD is decoupled from the frame loop: `_publishHud()` pushes a snapshot into `HudModel` (a `ChangeNotifier`) at ~12 Hz or on discrete events; `HudOverlay` uses `ListenableBuilder`. Do not read game fields directly from HUD widgets each frame.
- Input funnels through `steer(int direction)` (-1/1). Touch (`_InputLayer` swipe or half-screen tap), keyboard (`onKeyEvent`), and tilt (`TiltController`) all call it.

### Track and coordinates (`core/`)
- The track is a loop of `Segment`s of `GameConfig.segmentLength`. All z positions are wrapped into `[0, track.length)` via `track.wrap`; distances between two z values must use `track.signedDistance` (handles the seam). Never subtract raw z values.
- Lateral positions are normalised to `-1..1` across the road (`GameConfig.laneCenter(lane)`, `Player.offset`, `vehicleWidth`). World x in units only appears inside the renderer (`* GameConfig.roadWidth`).
- The camera sits at `game.position`; the player's car is `projector.playerZ` ahead of it (`game.playerTrackZ`). Collision/near-miss/pickup checks all use `playerTrackZ`, not `position`.
- `Track.generate` is deterministic per seed; a new seed is drawn per run. `_TrackBuilder.section` keeps hill height continuous and forces the loop back to y=0 so the seam is flat.

### Rendering (`world/world_component.dart`)
- Classic "road segments" pseudo-3D: iterate `drawDistance` segments from the camera's segment, accumulate curve (`x += dx; dx += seg.curve`), project `p1`/`p2` with `Projector`, skip segments behind the camera or hidden behind a hill crest (`maxY` clipping), stamp visible ones with the frame counter.
- Sprites (traffic, pickups) are drawn after the road, only for segments stamped this frame, sorted far → near, and clipped to `seg.clip` so they hide behind hills. Vehicles are drawn by `VehiclePainter` (rear silhouettes per `VehicleKind`), the player last.
- `WorldPalette.at(dayPhase)` interpolates the day/night colour set; `SkyPainter` handles the parallax backdrop. Screen effects (nitro streaks, shake, vignette) and floating texts are drawn on top.
- `ScreenPoint` scratch objects live on `Segment` and are reused every frame; avoid allocating in the render loop.

### Tuning
Every gameplay/geometry constant lives in `core/game_config.dart` (speeds, spawn windows, `blockWindow`, `sameLaneGap`, collision lengths, power-up timings). Change balance there first; `TrafficManager` and `TrafficRacerGame` read from it rather than holding their own magic numbers. Unit conversions for display (`_unitsPerKmh`, `_unitsPerMeter`) live in `TrafficRacerGame`.

### Traffic AI (`game/traffic_manager.dart`)
`maintain` tops up vehicles to `trafficCountForLevel`, spawning only where the lane is free (`sameLaneGap`) and at least one lane stays open within `blockWindow` (`_leavesAGap`). `_regulateSpeed` is car-following plus wall avoidance: a vehicle caps its speed to the slowest car ahead when every other lane is occupied nearby, and eases back to `cruiseSpeed` when clear. The test in `test/traffic_manager_test.dart` encodes the "never block all lanes" invariant.

### Services
All services swallow platform failures (audio backend missing, no accelerometer, prefs unavailable) and log with `debugPrint` so the game keeps running on desktop/web/simulators. Settings and high scores are `ValueNotifier`s persisted with `shared_preferences`.
