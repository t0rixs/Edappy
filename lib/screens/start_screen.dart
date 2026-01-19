import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  final int highScore;
  final VoidCallback onStart;
  final VoidCallback onRanking;

  const StartScreen({
    super.key,
    required this.highScore,
    required this.onStart,
    required this.onRanking,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'FLAPPY EDA',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 8, color: Colors.blueAccent)],
            fontFamily: 'Courier',
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: onStart,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/eda_normal.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'HIGH SCORE: $highScore',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.yellow,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: onRanking,
          icon: const Icon(Icons.leaderboard),
          label: const Text('RANKING'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: onStart,
          child: const Text(
            'TAP TO START',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }
}
