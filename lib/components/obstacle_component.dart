import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/traffic_racer_game.dart';
import 'icon_component.dart';
import 'dart:math';

class ObstacleComponent extends IconComponent {
  final TrafficRacerGame game;

  ObstacleComponent(this.game, IconData icon)
      : super(
          icon: icon,
          size: Vector2(50, 50),
          position: Vector2(0, 0),
          color: Colors.red,
        );

  static Future<ObstacleComponent> create(TrafficRacerGame game) async {
    final random = Random();
    final obstacleIcons = [
      Icons.directions_car,
      Icons.local_shipping,
      Icons.motorcycle,
      Icons.pedal_bike,
      Icons.fire_truck,
    ];
    final icon = obstacleIcons[random.nextInt(obstacleIcons.length)];
    final obstacle = ObstacleComponent(game, icon);

    const minX = 20.0;
    final maxX = game.size.x - obstacle.size.x - 20.0;
    final obstacleX = minX + random.nextDouble() * (maxX - minX);

    obstacle.position = Vector2(obstacleX, -obstacle.size.y);
    return obstacle;
  }
}
