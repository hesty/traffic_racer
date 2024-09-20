import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/traffic_racer_game.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/landing_page_overlay.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Traffic Racer',
      home: Scaffold(
        body: GameWidget<TrafficRacerGame>(
          game: TrafficRacerGame(),
          overlayBuilderMap: {
            'gameOver': (context, game) => GameOverOverlay(game: game),
            'landingPage': (context, game) => LandingPageOverlay(game: game),
          },
          initialActiveOverlays: const ['landingPage'],
        ),
      ),
    ),
  );
}
