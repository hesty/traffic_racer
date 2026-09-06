import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_traffic_rush/game/progression_coordinator.dart';
import 'package:turbo_traffic_rush/game/power_up_manager.dart';
import 'package:turbo_traffic_rush/game/traffic_racer_game.dart';
import 'package:turbo_traffic_rush/overlays/game_over_overlay.dart';
import 'package:turbo_traffic_rush/overlays/garage_overlay.dart';
import 'package:turbo_traffic_rush/overlays/hud_overlay.dart';
import 'package:turbo_traffic_rush/overlays/menu_overlay.dart';
import 'package:turbo_traffic_rush/overlays/paywall_overlay.dart';
import 'package:turbo_traffic_rush/overlays/pause_overlay.dart';
import 'package:turbo_traffic_rush/progression/run_stats.dart';
import 'package:turbo_traffic_rush/progression/subscription.dart';
import 'package:turbo_traffic_rush/services/high_score_service.dart';
import 'package:turbo_traffic_rush/services/settings_service.dart';

/// Lays every overlay out on a small and a tall phone. A RenderFlex overflow
/// throws in tests, so this guards the busier menu and result screens.
void main() {
  const sizes = [
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(768, 1024),
  ];

  TrafficRacerGame makeGame({bool finishRun = true}) {
    final progression = ProgressionCoordinator();
    progression.garage.creditCoins(480);
    // No store answers in a test, so hand the paywall its widest state.
    progression.purchases.debugSetOffers(const [
      SubscriptionOffer(
        id: r'$rc_monthly',
        period: PassPeriod.monthly,
        priceLabel: '149,99 TL',
        price: 149.99,
      ),
      SubscriptionOffer(
        id: r'$rc_annual',
        period: PassPeriod.annual,
        priceLabel: '999,99 TL',
        price: 999.99,
        pricePerMonthLabel: '83,33 TL',
      ),
    ]);
    progression.onRunStarted();
    // Complete everything so the result screen shows its longest form.
    const huge = RunStats(
      distanceMeters: 100000,
      nearMisses: 1000,
      bestCombo: 100,
      overtakes: 1000,
      powerUpsCollected: 100,
      level: 50,
      surviveSeconds: 10000,
    );
    final game = TrafficRacerGame(
      settings: SettingsService(),
      highScores: HighScoreService(),
      progression: progression,
      random: Random(1),
    );
    if (finishRun) game.lastRunSummary = progression.onRunFinished(huge);
    game.isNewRecord = true;
    game.stats.score = 12345;
    game.hud.publish(
      score: 12345,
      level: 7,
      speedKmh: 240,
      combo: 5,
      comboProgress: 0.5,
      bestScore: 9000,
      powerUpProgress: {for (final type in PowerUpType.values) type: 0.7},
      coinsThisRun: 88,
    );
    return game;
  }

  Future<void> pumpOverlay(
    WidgetTester tester,
    Widget child,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason:
          '${child.runtimeType}: '
          '${error is FlutterError ? error.toStringDeep() : error}',
    );
  }

  for (final size in sizes) {
    for (final textScale in [1.0, 1.6]) {
      testWidgets(
        'overlays fit a ${size.width.toInt()}x${size.height.toInt()} screen at text scale $textScale',
        (tester) async {
          final game = makeGame();
          await pumpOverlay(
            tester,
            MenuOverlay(game: game),
            size,
            textScale: textScale,
          );
          await pumpOverlay(
            tester,
            GameOverOverlay(game: game),
            size,
            textScale: textScale,
          );
          await pumpOverlay(
            tester,
            GarageOverlay(game: game),
            size,
            textScale: textScale,
          );
          await pumpOverlay(
            tester,
            PaywallOverlay(game: game),
            size,
            textScale: textScale,
          );
          await pumpOverlay(
            tester,
            PauseOverlay(game: game),
            size,
            textScale: textScale,
          );
          await pumpOverlay(
            tester,
            HudOverlay(game: game),
            size,
            textScale: textScale,
          );
        },
      );
    }
  }

  testWidgets('race action is visible on a small phone and sound toggles', (
    tester,
  ) async {
    final game = makeGame();
    await pumpOverlay(tester, MenuOverlay(game: game), const Size(320, 568));
    expect(tester.getBottomRight(find.text('Start racing')).dy, lessThan(568));
    await tester.ensureVisible(find.byTooltip('Sound: on'));
    await tester.tap(find.byTooltip('Sound: on'));
    await tester.pump();
    expect(game.settings.soundEnabled.value, isFalse);
    expect(find.byTooltip('Sound: off'), findsOneWidget);
  });

  testWidgets('garage selects an owned car and explains locked coin cars', (
    tester,
  ) async {
    final game = makeGame(finishRun: false);
    game.progression.garage.buy('sedan_blue');
    game.progression.garage.select('sedan_amber');
    await pumpOverlay(tester, GarageOverlay(game: game), const Size(390, 844));
    await tester.tap(find.text('Cobalt'));
    await tester.pump();
    expect(game.progression.garage.selectedSkin.id, 'sedan_blue');
    expect(find.text('Cobalt'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('Shadow'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Shadow'));
    await tester.pumpAndSettle();
    final before = game.progression.garage.coins;
    await tester.tap(find.text('Shadow'));
    await tester.pump();
    expect(game.progression.garage.coins, before);
    expect(game.progression.garage.selectedSkin.id, 'sedan_blue');
    expect(find.text('${800 - before} more coins'), findsOneWidget);
  });
}
