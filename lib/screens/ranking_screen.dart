import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingScreen extends StatefulWidget {
  final int highScore;
  const RankingScreen({super.key, required this.highScore});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String? _userId;
  String? _userName;
  bool _isLoading = true;
  List<Map<String, dynamic>> _rankingData = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  Future<void> _initSequence() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId');
    final uname = prefs.getString('userName');

    setState(() {
      _userId = uid;
      _userName = uname;
    });

    if (uid != null && uname != null) {
      // 登録済みならスコア同期＆ランキング取得
      await _syncScore();
      await _fetchRanking();
    }

    setState(() {
      _isLoading = false;
    });
  }

  // ユーザー登録処理
  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    // ID生成 (int8に収まる範囲: timestamp * 1000 + random)
    // timestamp(13桁) * 1000 = 16桁 < int8最大(19桁)
    final intId =
        DateTime.now().millisecondsSinceEpoch * 1000 + Random().nextInt(1000);
    final newId = intId.toString();

    // 保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userId', newId);

    // 反映
    setState(() {
      _userName = name;
      _userId = newId;
    });

    // スコア同期とランキング取得
    await _syncScore(); // Changed to call without parameters
    await _fetchRanking();

    setState(() => _isLoading = false);
  }

  Future<void> _syncScore() async {
    // Changed function signature
    if (_userId == null || _userName == null) {
      debugPrint('Sync Error: userId or userName is null');
      return;
    }
    try {
      await Supabase.instance.client.from('ranking').upsert({
        'id': int.tryParse(_userId!) ?? 0, // DBのint8に合わせて数値型で送る
        'user_name': _userName,
        'score': widget.highScore,
        'lastedit_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> _fetchRanking() async {
    try {
      final response = await Supabase.instance.client
          .from('ranking')
          .select('user_name, score')
          .order('score', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          _rankingData = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 登録済みチェック
    final isRegistered = (_userId != null && _userName != null);

    return Scaffold(
      backgroundColor: const Color(0xFF4C3D32), // 地面っぽい色か、落ち着いた色
      appBar: AppBar(
        title: const Text('RANKING'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : !isRegistered
            ? _buildRegistrationForm()
            : _buildRankingList(),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ENTER YOUR NAME',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                hintText: 'Player Name',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'JOIN RANKING',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingList() {
    if (_rankingData.isEmpty) {
      return const Center(
        child: Text('No Data', style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankingData.length,
      itemBuilder: (context, index) {
        final item = _rankingData[index];
        final name = item['user_name'] ?? 'Unknown';
        final score = item['score'] ?? 0;
        final isMe = (name == _userName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.yellow.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: isMe ? Border.all(color: Colors.yellow, width: 2) : null,
          ),
          child: Row(
            children: [
              Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: isMe ? Colors.yellowAccent : Colors.lightBlueAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
