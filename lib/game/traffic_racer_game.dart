import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import '../components/car_component.dart';
import '../components/road_component.dart';
import '../components/obstacle_component.dart';
import 'package:flame/events.dart';

// TrafficRacerGame class: Main game class that manages the game logic and components
class TrafficRacerGame extends FlameGame with HorizontalDragDetector, HasCollisionDetection {
  late CarComponent car;
  late RoadComponent road1;
  late RoadComponent road2;
  final List<ObstacleComponent> obstacles = [];
  late TextComponent scoreText;
  bool isPaused = true;
  int score = 0;
  bool isGameOver = false;
  double elapsedTime = 0.0;
  Vector2? dragStartPosition;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.loadAllImages();

    road1 = await RoadComponent.create(this);
    road2 = await RoadComponent.create(this);
    road2.position.y = -size.y;
    await addAll([road1, road2]);

    car = await CarComponent.create(this);
    await add(car);

    await spawnObstacle();

    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, 50),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 20)),
    );
    await add(scoreText);
    pauseEngine();
    overlays.add('landingPage');
  }

  @override
  void update(double dt) {
    if (!isPaused && !isGameOver) {
      super.update(dt);

      elapsedTime += dt;
      score = (elapsedTime * 10).toInt();
      scoreText.text = 'Score: $score';

      updateRoads(dt);
      updateObstacles(dt);
      checkCollisions();
    }
  }

  void updateRoads(double dt) {
    const roadSpeed = 300.0;
    road1.position.y += roadSpeed * dt;
    road2.position.y += roadSpeed * dt;

    if (road1.position.y >= size.y) {
      road1.position.y = road2.position.y - size.y;
    }
    if (road2.position.y >= size.y) {
      road2.position.y = road1.position.y - size.y;
    }
  }

  void updateObstacles(double dt) {
    for (var obstacle in List.from(obstacles)) {
      obstacle.position.y += 300 * dt;
      if (obstacle.position.y > size.y) {
        remove(obstacle);
        obstacles.remove(obstacle);
        spawnObstacle();
      }
    }
  }

  void checkCollisions() {
    for (var obstacle in obstacles) {
      if (car.checkCollision(obstacle)) {
        gameOver();
        break;
      }
    }
  }

  Future<void> spawnObstacle() async {
    if (isGameOver) return;
    final obstacle = await ObstacleComponent.create(this);
    obstacles.add(obstacle);
    await add(obstacle);
  }

  void gameOver() {
    isGameOver = true;
    overlays.add('gameOver');
  }

  void reset() {
    isGameOver = false;
    score = 0;
    elapsedTime = 0.0;
    car.reset();

    // Clear obstacles and recreate
    for (var obstacle in obstacles) {
      obstacle.removeFromParent();
    }
    obstacles.clear();
    spawnObstacle();

    // Reset car position
    car.position = Vector2(size.x / 2, size.y - car.size.y - 20);

    // Reset roads
    road1.position.y = 0;
    road2.position.y = -size.y;

    // Update game state
    resumeEngine();
    overlays.remove('gameOver');
  }

  @override
  void onHorizontalDragStart(DragStartInfo info) {
    if (isPaused || isGameOver) return;
    dragStartPosition = info.eventPosition.global;
  }

  @override
  void onHorizontalDragUpdate(DragUpdateInfo info) {
    if (isPaused || isGameOver || dragStartPosition == null) return;

    final screenWidth = size.x;
    final laneWidth = screenWidth / 4; // Assuming 3 lanes
    final dragDistance = info.eventPosition.global.x - dragStartPosition!.x;
    final dragDirection = dragDistance.sign;

    // Move the car by one lane width in the drag direction
    if (dragDistance.abs() > laneWidth / 2) {
      final newX = (car.position.x + dragDirection * laneWidth).clamp(0.0, screenWidth - car.size.x);
      car.position.x = newX;

      // Reset drag start position to allow for consecutive lane changes
      dragStartPosition = info.eventPosition.global;
    }
  }

  @override
  void onHorizontalDragEnd(DragEndInfo info) {
    dragStartPosition = null;
  }

  @override
  void resumeEngine() {
    isPaused = false;
  }

  @override
  void pauseEngine() {
    isPaused = true;
  }
}
