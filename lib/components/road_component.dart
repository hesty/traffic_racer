import 'package:flame/components.dart';
import '../game/traffic_racer_game.dart';

class RoadComponent extends SpriteComponent {
  final TrafficRacerGame game;

  RoadComponent(this.game) : super(size: game.size);

  static Future<RoadComponent> create(TrafficRacerGame game) async {
    final component = RoadComponent(game);
    component.sprite = Sprite(game.images.fromCache('road.png'));
    return component;
  }

  void move(double dt, double speed) {
    position.y += speed * dt;
    if (position.y >= game.size.y) {
      position.y = -game.size.y;
    }
  }
}
