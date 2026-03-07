# ユメログ (GrowthEngine) - Claude Code 運用ガイド

## プロジェクト概要

- **ユメログ** - Flutter マルチプラットフォームアプリ (StudyQualificationApplication の Flutter 移植版)
- Web 体験版: GitHub Pages (`https://teppei19980914.github.io/GrowthEngine/`)
- ネイティブ版 (Android/iOS/Windows等) も同一リポジトリで管理
- Drift ORM + Riverpod 状態管理

## 運用フロー

以下のフローで運用する。

### Claude Code が担当 (ステップ 1)

1. **プログラム修正**: ソースコード修正時、対応するテストコードも必ず追加・修正する
   - コミット & プッシュはユーザーが手動で実施（GitHub Actions の無料枠節約のため）

### ユーザーが手動で実施 (ステップ 2)

2. **コミット & プッシュ**: 修正完了後、main ブランチにコミット & プッシュする

### GitHub Actions が担当 (ステップ 3, 4)

3. **テスト & デプロイ**: push をトリガーに `flutter analyze` → `flutter test --coverage` → `flutter build web` → GitHub Pages デプロイ を自動実行
4. **公開**: デプロイ成功後、GitHub Pages に自動反映

## コミットルール

- ローカルでのテスト実行は不要（GitHub Actions に一任）
- テストコードの追加・修正を伴わないソースコード変更はコミットしない
- コミットメッセージは変更内容を端的に記述する

## テストルール

- 全てのソースコード (生成コード・UI の catch 句等を除く) がテスト対象
- テストファイルは `test/` 配下にソースと対応する構造で配置
- Drift の `isNull` / `isNotNull` は flutter_test と競合するため `hide` する
- DateTime 比較は SQLite のミリ秒精度に注意し秒単位で切り捨てる

## ビルド

```bash
# ローカルテスト
flutter test

# 静的解析
flutter analyze

# Web ビルド (GitHub Pages 用)
flutter build web --release --base-href "/GrowthEngine/"
```

## GitHub Actions ワークフロー

- **deploy.yml**: main push 時 → テスト（カバレッジ付き） → GitHub Pages デプロイ
- **test.yml**: PR 時 → テスト（カバレッジ付き）のみ実行
- カバレッジレポートは各ワークフロー実行の Summary タブに出力される

## 技術スタック

- Flutter (Dart) - Web ターゲット
- Drift (SQLite ORM) + drift_worker.js (Web WASM)
- flutter_riverpod (状態管理)
- fl_chart (グラフ)
- go_router (ルーティング)
- shared_preferences (設定永続化)
