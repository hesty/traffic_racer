# AGENTS.md — Turbo Traffic Rush

Quick-reference for agents working in this repo. Every line answers: "Would an agent miss this without help?"

## Core facts

- **Game:** portrait pseudo-3D arcade racer, Flutter + Flame. Zero sprite sheets — road, vehicles, UI all drawn procedurally with `Canvas`.
- **No server.** Daily missions, coins, garage, streaks are all deterministic and local.
- **Targets:** Android (`com.hesty.mobile_game`) and iOS (`com.hesty.racer`). Tilt steering only on real mobile hardware.
- **Layering is strict:** `progression/` → `core/` + `entities/`; `services/` wraps progression; `game/` glues services to run; `overlays/` sits on top. Lower layers never import higher ones.

## Commands

```bash
flutter pub get                         # deps
flutter run                             # connected device / simulator
flutter analyze                         # lint
flutter test                            # 12 test files, ~1200 lines total
flutter test test/track_test.dart       # single file
flutter test --plain-name "road centre" # single test

# Debug shortcuts
flutter run --dart-define=TTR_AUTOSTART=true  # skips menu for quick QA

# Regenerate assets (not authored — always regenerate from source)
python3 scripts/generate_audio.py           # all WAVs in assets/audio/ (needs numpy)
flutter test tool/generate_app_icon.dart    # iOS + Android launcher icons

# iOS clean (requires sudo)
bash scripts/clean_ios.sh
```

## Testing quirks

- `SharedPreferences.setMockInitialValues({})` resets the prefs store — call it in `setUp()` before any service test (see `garage_test.dart`, `subscription_test.dart`, `progression_coordinator_test.dart`).
- `TestWidgetsFlutterBinding.ensureInitialized()` is needed only in tests that touch widgets/platform channels (`progression_coordinator_test.dart`, `subscription_test.dart`). Pure Dart tests do not need it.
- `test/render_test.dart` renders `VehiclePainter.draw()` into an offscreen `PictureRecorder` — any painter exception (bad gradient, NaN geometry) fails the build instead of producing a blank frame at runtime.
- `test/overlay_layout_test.dart` pumps each overlay at phone sizes with a deliberately wide test font; a `RenderFlex` overflow here is a real bug signal.
- Deterministic seeds: `Track.generate(seed:)` and `TrafficManager(random: Random(n))` for reproducible traffic tests.

## Key files / entry points

| What | Where |
|---|---|
| App entry | `lib/main.dart` — `GameWidget.controlled` with `overlayBuilderMap` |
| Game loop / simulation | `lib/game/traffic_racer_game.dart` — `update(dt)` drives everything |
| Tuning constants | `lib/core/game_config.dart` — speeds, spawn windows, coin rates, mission targets |
| Track generation | `lib/core/track.dart` — `Track.generate(seed:)` |
| Pseudo-3D projection | `lib/core/projection.dart` |
| Collision math | `lib/core/swept_collision.dart` |
| Traffic AI | `lib/game/traffic_manager.dart` — `_leavesAGap` invariant (never block all lanes) |
| Score / combos | `lib/game/score_keeper.dart` |
| Power-ups | `lib/game/power_up_manager.dart` |
| HUD decoupling | `lib/game/hud_model.dart` — `ChangeNotifier`, published at ~12 Hz, not every frame |
| Progression glue | `lib/game/progression_coordinator.dart` — hooks: `onRunStarted`, `onRunProgress`, `onRunFinished` |
| World renderer | `lib/world/world_component.dart` — single render pass, depth-sorted sprites |
| Vehicle painter | `lib/world/vehicle_painter.dart` — rear silhouettes per `VehicleKind` |
| Services | `lib/services/*.dart` — all swallow platform failures with `debugPrint` |
| Overlays | `lib/overlays/*.dart` — read game state, call game methods |

## Architecture rules (easy to break)

1. **Track z-coordinates:** all positions are wrapped into `[0, track.length)` via `track.wrap`. Distances must use `track.signedDistance(a, b)`. **Never** subtract raw z values — it breaks across the seam.
2. **Lateral positions** are normalised to `-1..1`. Screen x only appears inside `world_component.dart` (`* GameConfig.roadWidth`).
3. **Collision / near-miss / pickup checks** use `playerTrackZ` (player's position on the track), not `game.position` (camera).
4. **HUD is decoupled:** overlays must read `HudModel` (a `ChangeNotifier`), not game fields directly. The game publishes snapshots at ~12 Hz via `_publishHud()`.
5. **Overlays don't create new `GamePhase`s.** The garage is layered over the menu or game-over screen. The paywall is layered over whichever screen was active. Use `openGarage`/`closeGarage`/`openPaywall`/`closePaywall` on the game, not phase transitions.
6. **Power-up timers** live in `PowerUpManager.tick(dt)` and `ScoreKeeper.tick(dt)` — frame-time timers, not `dart:async`. Pausing the game freezes them for free.
7. **dt clamping:** `update()` clamps `dt` to 1/20 s. Slow-mo scales `worldDt` (traffic + position) while effect timers still use raw `dt`.

## Service pattern

Every service in `lib/services/`:
- Wraps a platform/persistence failure in `try/catch` and logs with `debugPrint` — the game keeps running on desktop/web/simulator even if the backend is missing.
- Most are `ChangeNotifier`s (garage, missions, streak). Settings and high scores are `ValueNotifier`s persisted with `shared_preferences`.
- `PurchaseService` is the only service that imports `purchases_flutter`. Everything above it sees `SubscriptionOffer`, a plain data class.
- RevenueCat public SDK keys live in `lib/services/revenuecat_keys.dart` (safe to commit). The API v2 secret key is dashboard-only.

## Monetisation notes

- Turbo Pass = RevenueCat entitlement `pass` (`GameConfig.passEntitlement`), monthly + annual plans from the `default` offering.
- Pass-only cars (`CarSkin.premium`) are **lent**, not owned: `Garage.unlockedIds` stays coin-only; `Garage.canDrive(id, passActive:)` asks the live entitlement.
- Four paywall triggers: menu button, result-screen banner, tapping a pass-only garage tile, and one automatic prompt after `GameConfig.paywallAutoPromptAfterRuns` runs.
- `passCoinMultiplier` (default 2.0) is the lever that turns the pass from cosmetic into economy. Set to 1.0 to make the game-over screen omit the pass line.

## Traffic AI invariant

`TrafficManager._leavesAGap()` guarantees at least one lane stays passable within `blockWindow` (`segmentLength * 10`). The test in `test/traffic_manager_test.dart` encodes this — never remove or weaken it.

## Coordinate cheatsheet

| Concept | Normalised | World units | Notes |
|---|---|---|---|
| Lane center | `GameConfig.laneCenter(lane)` | — | -1..1 range, 3 lanes |
| Vehicle width | `GameConfig.vehicleWidth` (0.42) | fraction of half-road | |
| Road width | `GameConfig.roadWidth` (2000) | world units | screen x = offset * roadWidth |
| Segment length | `GameConfig.segmentLength` (200) | world units | |
| Collision distance | `GameConfig.collisionLength` (~220) | world units | |
| Near-miss distance | `GameConfig.nearMissLength` (~320) | world units | |
| Same-lane min gap | `GameConfig.sameLaneGap` (2800) | world units | |
| Block window | `GameConfig.blockWindow` (2000) | world units | traffic AI invariant |

## When to touch what

- **Balance/tuning:** `lib/core/game_config.dart` and `lib/progression/car_catalog.dart` (car prices).
- **New sound:** edit `scripts/generate_audio.py`, then `python3 scripts/generate_audio.py`. Never edit WAVs by hand.
- **New icon size:** edit `tool/app_icon_painter.dart`, then `flutter test tool/generate_app_icon.dart`. Never edit PNGs by hand.
- **New car body:** add to `VehicleKind` enum in `entities/traffic_vehicle.dart`, add painter branches in `world/vehicle_painter.dart`, add catalog entry in `progression/car_catalog.dart`.
- **New mission kind:** add target tiers and reward entries to `GameConfig`, add tracker logic in `progression/mission_tracker.dart`.
- **Track geometry:** `lib/core/track.dart` — `_TrackBuilder.section` keeps hill height continuous and forces the loop back to y=0 at the seam.

## Files to avoid editing directly

- `assets/audio/*.wav` — regenerated from `scripts/generate_audio.py`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` — regenerated from `tool/app_icon_painter.dart`
- `android/app/src/main/res/mipmap-*/ic_launcher*.png` — same
- `pubspec.lock` — run `flutter pub get`, don't edit by hand
- `ios/Pods/`, `ios/Podfile.lock` — run `bash scripts/clean_ios.sh` to reset
