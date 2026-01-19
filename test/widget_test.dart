import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy/main.dart';

void main() {
  Widget app() => const MaterialApp(home: Flappy());

  testWidgets('start page', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Tap to Startxxx'), findsOneWidget); // スタート画面の文字
  });

  testWidgets('score is 0', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('0'), findsWidgets); // 初期のスコアは0のはず
  });

  testWidgets('test play all', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byType(GestureDetector));
    await tester.pump(); // setStateを反映
    // runningになればメッセージが消える
    expect(find.text('Tap to Start'), findsNothing);
    // 数秒待ってゲームオーバー画面にする
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('GAME OVER !\nTap to Restart'), findsOneWidget);
    // タップしてリスタートする
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    // リスタート直後はGAME OVERメッセージは消えるはず
    expect(find.text('GAME OVER !\nTap to Restart'), findsNothing);
  });
}
