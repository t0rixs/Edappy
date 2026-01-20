# Flappy Game

えだみさきの誕生日企画です。

## 🎮 **[▶️ ゲームをプレイする](https://t0rixs.github.io/Edappy/)**

## 📖 ゲームの説明

自身によって加速していくえだを、
あなたの操作で木に打ち付けないようにしよう！

## 🎮 基本ルール

### 操作方法
- **画面タップ**でえだが上昇します！それだけ！

## ⚡ ゲームの特徴

### アイテム
- ゲーム中に⚡マークのアイテムを取得すると「Confidence」が上昇
- Confidenceが高いほど、以下の効果が発生するよ！
  - 難易度が上昇！
  - 1回通過するごとの得点が増加！

- ゲーム中に🛡️マークのアイテムを取得すると「コモダシールド」が発動！
  - 木に1回だけ打ち付けても即死しない

### ランキング機能
- Supabaseでオンラインランキングがみれます！
- ユーザー名を登録してランキングに参加しよう！

## 🚀 実行方法

### 必要要件
- Flutter SDK
- Dart

### インストール
```bash
# 依存関係のインストール
flutter pub get

# 実行
flutter run
```

### ビルド
```bash
# Androidビルド
flutter build apk

# iOSビルド（Macのみ）
flutter build ios

# Webビルド
flutter build web
```

## 🛠️ 使用技術

- **Flutter**: クロスプラットフォームUIフレームワーク
- **Dart**: プログラミング言語
- **Supabase**: バックエンド（ランキング機能）
- **SharedPreferences**: ローカルストレージ（ハイスコア保存）

## 📁 プロジェクト構造

```
lib/
├── main.dart                 # エントリーポイント
├── game/
│   └── flappy_game.dart     # メインゲームロジック
├── screens/
│   ├── start_screen.dart    # スタート画面
│   ├── result_screen.dart   # リザルト画面
│   └── ranking_screen.dart  # ランキング画面
├── components/
│   ├── tree_trunk.dart      # 木の幹コンポーネント
│   └── wind_painter.dart    # 風のエフェクト
└── models/
    └── game_item.dart       # アイテムモデル
```

## 🎯 攻略のコツ

1. **最初はConfidenceを上げすぎない**: スピードが速くなりすぎると制御が難しくなります
2. **バリアを確保**: 1回のミスを許してくれるバリアは重要です
3. **タップのリズムを掴む**: 一定のリズムでタップすると安定します
4. **Confidenceを狙う**: 高得点を狙うなら積極的にConfidenceアイテムを取りましょう

---

Enjoy the game! 🎮✨
