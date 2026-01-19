import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int highScore;
  final int confidence;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const ResultScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.confidence,
    required this.onRetry,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'GAME OVER',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
            shadows: [Shadow(blurRadius: 8, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 40),
        _buildInfoRow('SCORE', '$score', Colors.white),
        if (score >= highScore && score > 0)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'NEW RECORD!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'HIGH SCORE: $highScore',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ),

        const SizedBox(height: 16),
        _buildInfoRow('CONFIDENCE', '$confidence', Colors.yellowAccent),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onHome,
              child: const Text('HOME'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: valueColor,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
          ),
        ),
      ],
    );
  }
}
