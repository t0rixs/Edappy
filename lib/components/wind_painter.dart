import 'dart:math';
import 'package:flutter/material.dart';

class WindPainter extends CustomPainter {
  final double factor; // 0.0 ~ 1.0
  final double scroll; // マイナス方向に進むオフセット

  WindPainter({required this.factor, required this.scroll});

  @override
  void paint(Canvas canvas, Size size) {
    if (factor <= 0) return;

    final paint = Paint()
      ..color = Colors.white
          .withOpacity(0.5 * factor) // 強さに応じて不透明度変更
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rng = Random(42); // シード固定で同じパターンを生成
    final w = size.width;
    final h = size.height;

    // 描画する線の数
    final count = 60;

    for (int i = 0; i < count; i++) {
      // 画面全体に配置
      final y = rng.nextDouble() * h;

      // 線の長さ
      final len = w * (0.1 + rng.nextDouble() * 0.2);

      // X座標 (scrollに合わせて移動)
      final loopW = w * 2.0;
      double startX = (rng.nextDouble() * loopW) + (scroll * loopW);

      // ループ補正
      startX = startX % loopW;
      if (startX > w) startX -= loopW;

      // 太さ
      paint.strokeWidth = (1.0 + rng.nextDouble() * 2.0) * (0.5 + 0.5 * factor);

      canvas.drawLine(Offset(startX, y), Offset(startX + len, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WindPainter oldDelegate) {
    return oldDelegate.scroll != scroll || oldDelegate.factor != factor;
  }
}
