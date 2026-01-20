import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_item.dart';
import '../components/tree_trunk.dart';
import '../components/wind_painter.dart';
import '../screens/start_screen.dart';
import '../screens/result_screen.dart';
import '../screens/ranking_screen.dart';

class FlappyGame extends StatefulWidget {
  const FlappyGame({super.key});
  @override
  State<FlappyGame> createState() => _FlappyGameState();
}

class _FlappyGameState extends State<FlappyGame> {
  // ゲーム状態
  Timer? _timer;
  bool _running = false;
  bool _gameOver = false;
  bool _dying = false; // 落下中の状態
  int confidence = 0;

  // ゲーム空間の座標 (0..1)
  double birdY = 0.5;
  double birdV = 0.0;
  // パイプ
  double pipeX = 1.2;
  double gapY = 0.5;

  int score = 0;
  int highScore = 0;
  String? userName;
  String? userId;

  bool _scoredThisPipe = false;
  // 穴あき生成用
  int _pipeCount = 0;
  int _nextSpecialTarget = 3;
  GameItem? _currentItem;

  // バリア・無敵状態
  bool _hasBarrier = false;
  DateTime? _invincibleUntil;

  // エフェクト用
  double _windOffset = 0.0;
  List<double> _grassPositions = []; // 草の位置リスト（ピクセル単位）
  double _screenWidth = 1200.0; // 画面幅（デフォルト値）

  // パラメータ
  static const double gravity = 0.001;
  static const double jumpV = -0.020;
  static const double pipeSpeed = 0.01;
  static const double gapSize = 0.40;
  static const double birdRadius = 0.04;
  static const double itemRadius = 0.03; // アイテムの半径
  static const double pipeWidth = 0.16;
  static const int tickMs = 16;

  final _rng = Random();

  double get _speedMultiplier {
    double val = 1.0;
    for (int i = 1; i <= confidence; i++) {
      val += 1.0 / (i + 2);
    }
    return val;
  }

  bool get _isInvincible =>
      _invincibleUntil != null && DateTime.now().isBefore(_invincibleUntil!);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
      userName = prefs.getString('userName');
      userId = prefs.getString('userId');
    });
  }

  Future<void> _updateHighScore() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
      // ハイスコア更新時にサーバーも更新（IDがあれば）
      if (userId != null && userName != null) {
        _updateScoreOnServer();
      }
    }
  }

  Future<void> _updateScoreOnServer() async {
    if (userId == null || userName == null) return;
    try {
      await Supabase.instance.client.from('ranking').upsert({
        'id': int.tryParse(userId!) ?? 0, // DBのint8に合わせて数値型で送る
        'user_name': userName,
        'score': highScore,
        'lastedit_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error uploading score: $e');
    }
  }

  void _openRankingScreen() async {
    // 現在のスコアを念のため送信
    await _updateScoreOnServer();
    if (!mounted) return;

    // 画面遷移
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RankingScreen(highScore: highScore),
      ),
    );

    // 戻ってきたらユーザー情報を再読み込み（名前登録された可能性があるため）
    _loadUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _gameOver = false;
      _dying = false;
      score = 0;
      confidence = 0;
      birdY = 0.5;
      birdV = 0.0;
      pipeX = 1.2;

      _hasBarrier = false;
      _invincibleUntil = null;

      // 生成ロジック初期化
      _pipeCount = 0;
      _nextSpecialTarget = 3 + _rng.nextInt(2); // 3~4
      _currentItem = null;

      // 草の初期配置
      _initGrass();

      _resetGap();
      _scoredThisPipe = false;
    });

    _timer = Timer.periodic(
      const Duration(milliseconds: tickMs),
      (_) => _tick(),
    );
  }

  void _goHome() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _gameOver = false;
      _dying = false;
      score = 0;
      confidence = 0;
      birdY = 0.5;
      birdV = 0.0;
      pipeX = 1.2;
    });
  }

  void _initGrass() {
    _grassPositions.clear();
    double pos = 0;
    // 画面の2倍の幅まで草を配置
    while (pos < 2400) {
      _grassPositions.add(pos);
      pos += 100 + _rng.nextDouble() * 100; // 100~300pxの間隔
    }
  }

  void _resetGap() {
    gapY = 0.25 + _rng.nextDouble() * 0.5;

    // パイプ更新時にカウントアップ
    _pipeCount++;
    if (_pipeCount >= _nextSpecialTarget) {
      _pipeCount = 0;
      _nextSpecialTarget = 3 + _rng.nextInt(4); // 次のターゲット設定(3~6)

      const margin = 0.02;
      final minY = (gapY - gapSize / 2) + itemRadius + margin;
      final maxY = (gapY + gapSize / 2) - itemRadius - margin;

      if (maxY > minY) {
        final itemY = minY + _rng.nextDouble() * (maxY - minY);
        final type = (_rng.nextDouble() < 0.3)
            ? ItemType.barrier
            : ItemType.confidence;

        _currentItem = GameItem(type: type, y: itemY, xOffset: pipeWidth / 2);
      } else {
        final type = (_rng.nextDouble() < 0.3)
            ? ItemType.barrier
            : ItemType.confidence;
        _currentItem = GameItem(type: type, y: gapY, xOffset: pipeWidth / 2);
      }
    } else {
      _currentItem = null;
    }
  }

  void _tap() {
    if (_gameOver || !_running) {
      _start();
      return;
    }
    // 落下中は入力を無効化
    if (_dying) return;
    setState(() => birdV = jumpV);
  }

  void _tick() {
    if (!_running || _gameOver) return;

    final m = _speedMultiplier;

    birdV += gravity * 1;
    birdY += birdV * 1;

    // 落下中は地面到達チェック
    if (_dying) {
      if (birdY >= 1.0 - birdRadius) {
        // 地面に到達したらゲームオーバー
        _gameOverState();
        return;
      }
      setState(() {});
      return;
    }

    pipeX -= pipeSpeed * m;

    _windOffset -= 0.02 * m;
    if (_windOffset < -1.0) _windOffset += 1.0;

    // 草のスクロール（パイプと同じスピード）
    final grassSpeed = pipeSpeed * m * _screenWidth;
    for (int i = 0; i < _grassPositions.length; i++) {
      _grassPositions[i] -= grassSpeed;
      // 画面左に消えたら右側に再配置
      if (_grassPositions[i] < -100) {
        _grassPositions[i] += 2400;
      }
    }

    if (pipeX < -pipeWidth) {
      pipeX = 1.2;
      _resetGap();
      _scoredThisPipe = false;
    }
    const birdX = 0.3;
    if (!_scoredThisPipe && pipeX + pipeWidth < birdX) {
      score += pow(2, confidence).toInt();
      _scoredThisPipe = true;
    }

    if (_currentItem != null && !_currentItem!.collected) {
      final itemX = pipeX + _currentItem!.xOffset;
      final itemY = _currentItem!.y;
      if (_checkItemHit(birdX, birdY, itemX, itemY)) {
        _collectItem(_currentItem!);
      }
    }

    final bool hitP = _hitPipe(birdX);
    final bool hitW = _hitWall();

    if (hitP || hitW) {
      if (hitP && !hitW) {
        if (_isInvincible) {
          // pass
        } else if (_hasBarrier) {
          _activateInvincibility();
        } else {
          // 木にぶつかった - 落下アニメーション開始
          _startDying();
          return;
        }
      } else {
        // 壁にぶつかった - 即ゲームオーバー
        _gameOverState();
        return;
      }
    }
    setState(() {});
  }

  void _startDying() {
    setState(() {
      _dying = true;
      _hasBarrier = false;
      _invincibleUntil = null;
    });
  }

  void _gameOverState() {
    setState(() {
      _gameOver = true;
      _running = false;
      _dying = false;
      _invincibleUntil = null;
    });
    _updateHighScore();
  }

  void _activateInvincibility() {
    setState(() {
      _hasBarrier = false;
      _invincibleUntil = DateTime.now().add(const Duration(seconds: 1));
    });
  }

  void _collectItem(GameItem item) {
    setState(() {
      item.collected = true;
      if (item.type == ItemType.confidence) {
        confidence++;
      } else if (item.type == ItemType.barrier) {
        _hasBarrier = true;
      }
    });
  }

  bool _checkItemHit(double birdX, double birdY, double itemX, double itemY) {
    final dx = birdX - itemX;
    final dy = birdY - itemY;
    final dist = sqrt(dx * dx + dy * dy);
    return dist < (birdRadius + itemRadius);
  }

  bool _hitWall() {
    return (birdY - birdRadius) < 0.0 || (birdY + birdRadius) > 1.0;
  }

  bool _hitPipe(double birdX) {
    final inX =
        birdX + birdRadius > pipeX && birdX - birdRadius < pipeX + pipeWidth;
    if (!inX) return false;

    final gapTop = gapY - gapSize / 2;
    final gapBottom = gapY + gapSize / 2;

    final inGap =
        (birdY - birdRadius) >= gapTop && (birdY + birdRadius) <= gapBottom;
    if (inGap) return false;

    return true;
  }

  double _birdAngle() {
    final v = birdV.clamp(-0.05, 0.08);
    return (v / 0.08) * (pi / 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (_running) _tap();
        },
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            // 画面幅を状態に保存
            if (_screenWidth != w) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _screenWidth = w;
                });
              });
            }
            double toPxX(double x) => x * w;
            double toPxY(double y) => y * h;
            final gapTop = gapY - gapSize / 2;
            final gapBottom = gapY + gapSize / 2;
            final base = min(w, h);
            final birdSize = base * (birdRadius * 2);
            final itemSizePx = base * (itemRadius * 2);
            final boxSize = birdSize * 2.0;

            // 鳥の画像を状態に応じて変更
            final birdImage = (_dying || _gameOver)
                ? 'assets/eda_lose.png'
                : (confidence > 5)
                ? 'assets/eda_fever.png'
                : 'assets/eda_normal.png';

            final double windIntensity = (confidence / 5.0).clamp(0.0, 1.0);

            return Stack(
              children: [
                // Sky
                Container(color: const Color(0xFF8ED6FF)),

                // Wind
                if (windIntensity > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WindPainter(
                        factor: windIntensity,
                        scroll: _windOffset,
                      ),
                    ),
                  ),

                // Upper Pipe
                Positioned(
                  left: toPxX(pipeX),
                  top: 0,
                  width: toPxX(pipeWidth),
                  height: toPxY(gapTop),
                  child: TreeTrunk(
                    width: toPxX(pipeWidth),
                    height: toPxY(gapTop),
                  ),
                ),

                // Lower Pipe
                Positioned(
                  left: toPxX(pipeX),
                  top: toPxY(gapBottom),
                  width: toPxX(pipeWidth),
                  height: toPxY(1 - gapBottom),
                  child: TreeTrunk(
                    width: toPxX(pipeWidth),
                    height: toPxY(1 - gapBottom),
                  ),
                ),

                // Ground
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 20.0,
                  child: Container(
                    color: const Color.fromARGB(255, 86, 55, 50),
                  ),
                ),

                // Grass (decorative, no collision)
                ..._grassPositions.map((pos) {
                  return Positioned(
                    bottom: 20.0, // 土の真上
                    left: pos,
                    child: Image.asset(
                      'assets/grass.png',
                      height: 30.0,
                      fit: BoxFit.fitHeight,
                    ),
                  );
                }).toList(),

                // Items
                if (_currentItem != null && !_currentItem!.collected) ...[
                  Builder(
                    builder: (context) {
                      final isConfidence =
                          _currentItem!.type == ItemType.confidence;
                      final color = isConfidence
                          ? Colors.yellow
                          : Colors.cyanAccent;
                      final shadow = isConfidence ? Colors.orange : Colors.blue;
                      final icon = isConfidence ? Icons.flash_on : Icons.shield;

                      return Positioned(
                        left:
                            toPxX(pipeX + _currentItem!.xOffset) -
                            itemSizePx / 2,
                        top: toPxY(_currentItem!.y) - itemSizePx / 2,
                        width: itemSizePx,
                        height: itemSizePx,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: shadow,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              size: 16,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // Bird
                Positioned(
                  left: toPxX(0.3) - boxSize / 2,
                  top: toPxY(birdY) - boxSize / 2,
                  width: boxSize,
                  height: boxSize,
                  child: Center(
                    child: Transform.rotate(
                      angle: _birdAngle(),
                      child: Transform.scale(
                        scaleX: -1,
                        child: Image.asset(birdImage),
                      ),
                    ),
                  ),
                ),

                // Barrier
                if (_hasBarrier)
                  Positioned(
                    left: toPxX(0.3) + birdSize * 0.2,
                    top: toPxY(birdY) - birdSize * 0.6,
                    width: birdSize * 1.2,
                    height: birdSize * 1.2,
                    child: Image.asset('assets/barrier.png'),
                  ),

                // Invincible Effect
                if (_isInvincible)
                  Positioned(
                    left: toPxX(0.3) - birdSize,
                    top: toPxY(birdY) - birdSize,
                    width: birdSize * 2,
                    height: birdSize * 2,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                // Info
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black45),
                          ],
                        ),
                      ),
                      Text(
                        'Confidence: $confidence',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellowAccent,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlay Screens
                if (!_running)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: _gameOver
                          ? ResultScreen(
                              score: score,
                              highScore: highScore,
                              confidence: confidence,
                              onRetry: _start,
                              onHome: _goHome,
                            )
                          : StartScreen(
                              highScore: highScore,
                              onStart: _start,
                              onRanking: _openRankingScreen,
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
