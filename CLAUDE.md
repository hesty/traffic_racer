# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Turbo Traffic Rush (package name `turbo_traffic_rush`): a portrait-only, pseudo-3D arcade traffic racer built with Flutter and Flame. Three lanes, swipe/tap/keyboard/tilt lane changes, near-miss combos, power-ups, procedurally generated looping track. Retention layer: daily missions, a coin economy with a garage of unlockable cars, and a daily play streak. Monetisation: the Turbo Pass, a monthly/annual RevenueCat subscription that lends out four pass-only cars. Targets Android and iOS (bundle ids `com.hesty.mobile_game` / `com.hesty.racer`). No sprite sheets or image assets: the whole world, the menu backdrop and the garage previews are drawn procedurally with `Canvas` calls.

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

The iOS app icon is generated too, not authored: `flutter test tool/generate_app_icon.dart`
(from the repo root) redraws every PNG in `ios/Runner/Assets.xcassets/AppIcon.appiconset`
plus its `Contents.json` from `tool/app_icon_painter.dart`, which paints the icon with the
same `VehiclePainter` and dusk palette the game uses. Each size is rendered from the vector,
and written as an opaque 24-bit PNG because App Store Connect rejects a marketing icon with
an alpha channel. Edit the painter, never the PNGs.

Tests are mostly pure Dart unit tests over `core/`, `game/`, `progression/` and the pass rules in `test/subscription_test.dart`, relying on deterministic seeds (`Track.generate(seed:)`, `Random(n)` injected into `TrafficManager`, `MissionCatalog.forDay(dayKey)`) and injected clocks (`now:` on `MissionsService`/`StreakService`/`ProgressionCoordinator`). Two deliberate exceptions use `testWidgets`: `test/render_test.dart` renders a full run offscreen so painter exceptions fail the build, and `test/overlay_layout_test.dart` pumps each overlay at phone sizes so a `RenderFlex` overflow fails (the test font is much wider than real fonts, so horizontal fits are conservative). Persisting services are tested against `SharedPreferences.setMockInitialValues({})`. No Flame `GameWidget` in tests.

## Architecture

Layers, dependency direction top → bottom (lower layers never import higher ones):

```
main.dart            GameWidget.controlled + overlayBuilderMap (menu/hud/pause/gameOver/garage/paywall)
overlays/            Flutter widgets shown over the game; read game state, call game methods
game/                TrafficRacerGame (simulation + phase machine), TrafficManager, ScoreKeeper,
                     PowerUpManager, HudModel, ProgressionCoordinator (run hooks → progression)
world/               WorldComponent (single Flame Component that renders everything), painters, palette
services/            AudioService, SettingsService, HighScoreService, TiltController,
                     MissionsService, GarageService, StreakService, PurchaseService,
                     PaywallPromptService, RevenueCatKeys, StoreLinks
progression/         pure Dart, no Flutter/Flame: Mission/MissionCatalog/MissionTracker/RunStats,
                     CarCatalog/Garage/Wallet/CoinFormula, Streak/StreakCalculator,
                     SubscriptionOffer, day keys
entities/            plain data classes: Player, TrafficVehicle, PowerUpPickup
core/                GameConfig (all tunables), Projector (perspective math), Track/Segment
```

`progression/` imports only `core/` and `entities/`; `services/` wraps it with persistence; `game/` glues it to a run through `ProgressionCoordinator`.

### Simulation model (`game/traffic_racer_game.dart`)
- `TrafficRacerGame` is a `FlameGame` but almost nothing is a Flame component. Entities are plain lists (`traffic.vehicles`, `pickups`, `floatingTexts`, `debris`) mutated in `update()`. Only two components are added: `WorldComponent` (render) and `_InputLayer` (touch).
- `GamePhase` (`menu, playing, paused, crashing, gameOver`) drives `update()`. Overlay add/remove happens only inside the lifecycle methods (`startRun`, `pauseRun`, `resumeRun`, `backToMenu`, `_crash`, `_finishRun`, `openGarage`, `closeGarage`). Keep overlay bookkeeping there; overlays themselves just call these. The garage is an overlay layered over the menu or the game-over screen; no new phase.
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

### Progression (`game/progression_coordinator.dart`, `progression/`, `services/`)
- `TrafficRacerGame` calls three hooks: `onRunStarted` (roll/refresh missions, register the streak day), `onRunProgress` at the 12 Hz HUD cadence with a `RunStats` snapshot (mission ratchet), `onRunFinished` (coin payout) returning a `RunSummary` the game-over overlay reads via `game.lastRunSummary`.
- Missions are deterministic per calendar day (`MissionCatalog.forDay(yyyymmdd)`); cumulative kinds add across the day's runs, the rest count the best single run. Rewards are credited the moment a mission completes; the all-done bonus once per day.
- `GarageService`/`MissionsService` are `ChangeNotifier`s (compound state); `StreakService` exposes a `ValueNotifier`. All swallow prefs failures like the older services.
- Mission targets, rewards, coin rates and streak caps live in `GameConfig`; car prices live in `CarCatalog`.

### Monetisation (`services/purchase_service.dart`, `overlays/paywall_overlay.dart`)
- The Turbo Pass is one RevenueCat entitlement (`GameConfig.passEntitlement`, `pass`) sold as a monthly and an annual plan out of the `default` offering. `PurchaseService` is the only file that imports `purchases_flutter`; everything above it sees `SubscriptionOffer`, a plain data class in `progression/`.
- Like every other service it swallows platform failures. With no key, no store or no network the pass reads as inactive, `offers` stays empty and the paywall lays out in its "unavailable" state — which is what tests and desktop builds get. The last known entitlement is cached in prefs so an offline launch does not strip the player's cars.
- Pass-only cars (`CarSkin.premium`) are never *owned*, only lent: `Garage.unlockedIds` stays coin-only and `Garage.canDrive(id, passActive:)` asks the live entitlement. `ProgressionCoordinator` subscribes `GarageService.onPassChanged` to `PurchaseService`, so a lapsed pass drops the selection back to the default car.
- Four paywall triggers: the menu button, a `PassBanner` on the result screen, tapping a pass-only garage tile, and one automatic prompt after `GameConfig.paywallAutoPromptAfterRuns` runs (`PaywallPromptService`, once per install).
- The paywall is an overlay like the garage — no new `GamePhase`. `openPaywall`/`closePaywall` remember which screen to restore, including the garage.
- `GameConfig.passCoinMultiplier` is the lever that turns the pass from cosmetic into an economy perk; at 1.0 the game-over screen simply omits the pass line.
- Public SDK keys live in `services/revenuecat_keys.dart` (safe to commit; `--dart-define` overrides them). The API v2 secret key is dashboard-only and never enters the app. `services/store_links.dart` holds the terms/privacy URLs the stores require on a paywall.

### Tuning
Every gameplay/geometry constant lives in `core/game_config.dart` (speeds, spawn windows, `blockWindow`, `sameLaneGap`, collision lengths, power-up timings). Change balance there first; `TrafficManager` and `TrafficRacerGame` read from it rather than holding their own magic numbers. Unit conversions for display (`_unitsPerKmh`, `_unitsPerMeter`) live in `TrafficRacerGame`.

### Traffic AI (`game/traffic_manager.dart`)
`maintain` tops up vehicles to `trafficCountForLevel`, spawning only where the lane is free (`sameLaneGap`) and at least one lane stays open within `blockWindow` (`_leavesAGap`). `_regulateSpeed` is car-following plus wall avoidance: a vehicle caps its speed to the slowest car ahead when every other lane is occupied nearby, and eases back to `cruiseSpeed` when clear. The test in `test/traffic_manager_test.dart` encodes the "never block all lanes" invariant.

### Services
All services swallow platform failures (audio backend missing, no accelerometer, prefs unavailable) and log with `debugPrint` so the game keeps running on desktop/web/simulators. Settings and high scores are `ValueNotifier`s persisted with `shared_preferences`.
