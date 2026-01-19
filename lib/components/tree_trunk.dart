import 'package:flutter/material.dart';

class TreeTrunk extends StatelessWidget {
  final double height;
  final double width;

  const TreeTrunk({super.key, required this.height, this.width = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, height), painter: _TrunkPainter());
  }
}

class _TrunkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.brown[800]!, Colors.brown[600]!, Colors.brown[900]!],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 幹のメイン形状
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);

    // 樹皮っぽい縦ラインの追加
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 2;

    for (double i = 0.2; i < 1.0; i += 0.3) {
      canvas.drawLine(
        Offset(size.width * i, 0),
        Offset(size.width * i, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
