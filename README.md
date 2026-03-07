# ユメログ (YumeLog)

学習計画管理アプリ — Flutter/Dart による全面書き直し版。

Python/PySide6 版の [StudyQualificationApplication](https://github.com/) を Flutter で再構築し、クロスプラットフォーム対応を実現。

## 機能一覧

| 機能 | 説明 |
|------|------|
| ダッシュボード | カスタマイズ可能な学習サマリーウィジェット |
| 3W1H 目標管理 | What/Why/When/How フレームワークで目標を設定 |
| ガントチャート | タスクの進捗をガントチャートで可視化 |
| 書籍管理 | 学習書籍の登録・進捗管理・読了レビュー |
| 統計 | 学習時間・ストリーク・自己ベスト・実施率を分析 |
| 通知・実績 | 学習マイルストーン達成時の通知 |
| 設定 | テーマ切替（Catppuccin Mocha/Latte）、データ管理 |

## 技術スタック

| 項目 | 技術 |
|------|------|
| フレームワーク | Flutter 3.x |
| 言語 | Dart 3.x |
| 状態管理 | Riverpod 2.x |
| ローカル DB | Drift（SQLite） |
| ルーティング | go_router |
| テーマ | Material 3 + Catppuccin |
| テスト | flutter_test |

## ディレクトリ構成

```
lib/
├── main.dart                  # エントリポイント
├── app.dart                   # MaterialApp + go_router
├── models/                    # データモデル（Goal, Task, Book, StudyLog, Notification）
├── database/                  # Drift DB定義
│   ├── app_database.dart      # Database クラス
│   ├── tables/                # テーブル定義
│   └── daos/                  # Data Access Objects
├── services/                  # ビジネスロジック
├── providers/                 # Riverpod Providers
├── theme/                     # Catppuccin テーマ定義
├── pages/                     # ページ（6ページ）
├── widgets/                   # 再利用可能ウィジェット
└── dialogs/                   # ダイアログ

test/
├── models/                    # モデル単体テスト
├── database/                  # DAO テスト
├── services/                  # サービステスト
├── pages/                     # ページウィジェットテスト
├── dialogs/                   # ダイアログテスト
├── widgets/                   # ウィジェットテスト
├── integration/               # 統合テスト
└── helpers/                   # テストヘルパー
```

## セットアップ

```bash
# Flutter SDK が必要（3.x）
flutter --version

# 依存関係インストール
flutter pub get

# Drift コード生成
dart run build_runner build
```

## 開発コマンド

```bash
# テスト実行（372テスト）
flutter test

# 静的解析
flutter analyze

# ビルド（Windows）
flutter build windows --debug

# ビルド（Android）
flutter build apk --debug
```

## テスト

テストは 5 層で構成:

| 層 | テスト数 | 対象 |
|----|---------|------|
| モデル | 96 | データモデルのバリデーション・シリアライズ |
| DAO | 59 | データベース CRUD 操作 |
| サービス | 161 | ビジネスロジック・統計計算 |
| ウィジェット | 48 | ページ・ダイアログ・通知ボタン |
| 統合 | 8 | アプリ全体のフロー |

## 対応プラットフォーム

- Android
- iOS
- Windows（Developer Mode 必要）
- macOS
- Web（SQLite WASM 対応が必要 — 現在 FFI ベース）

## テーマ

[Catppuccin](https://github.com/catppuccin/catppuccin) カラーパレットを採用:

- **ダークモード**: Catppuccin Mocha
- **ライトモード**: Catppuccin Latte

## ライセンス

Private
