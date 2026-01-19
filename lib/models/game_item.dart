enum ItemType { confidence, barrier }

class GameItem {
  final ItemType type;
  final double xOffset; // パイプ基準の相対X座標
  final double y; // 画面全体のY座標(0.0-1.0)
  bool collected = false;

  GameItem({required this.type, required this.y, this.xOffset = 0.0});
}
