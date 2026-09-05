import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/progression_coordinator.dart';
import 'game/traffic_racer_game.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/garage_overlay.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/menu_overlay.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/paywall_overlay.dart';
import 'overlays/ui_theme.dart';
import 'services/high_score_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final settings = SettingsService();
  final highScores = HighScoreService();
  final progression = ProgressionCoordinator();
  await Future.wait([settings.load(), highScores.load(), progression.load()]);

  runApp(TurboTrafficRushApp(
    settings: settings,
    highScores: highScores,
    progression: progression,
  ));
}

class TurboTrafficRushApp extends StatelessWidget {
  const TurboTrafficRushApp({
    super.key,
    required this.settings,
    required this.highScores,
    required this.progression,
  });

  final SettingsService settings;
  final HighScoreService highScores;
  final ProgressionCoordinator progression;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turbo Traffic Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: UiTheme.pass,
          brightness: Brightness.dark,
          primary: UiTheme.pass,
          secondary: UiTheme.accent,
          surface: const Color(0xFF101D30),
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF05071A),
        body: GameWidget<TrafficRacerGame>.controlled(
          gameFactory: () => TrafficRacerGame(
            settings: settings,
            highScores: highScores,
            progression: progression,
          ),
          overlayBuilderMap: {
            Overlays.menu: (_, game) => MenuOverlay(game: game),
            Overlays.hud: (_, game) => HudOverlay(game: game),
            Overlays.pause: (_, game) => PauseOverlay(game: game),
            Overlays.gameOver: (_, game) => GameOverOverlay(game: game),
            Overlays.garage: (_, game) => GarageOverlay(game: game),
            Overlays.paywall: (_, game) => PaywallOverlay(game: game),
          },
        ),
      ),
    );
  }
}
