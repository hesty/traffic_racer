import 'package:flutter/material.dart';
import '../game/traffic_racer_game.dart';

class LandingPageOverlay extends StatelessWidget {
  final TrafficRacerGame game;

  const LandingPageOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  'Turbo Traffic Rush',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('landingPage');
                game.resumeEngine();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}
