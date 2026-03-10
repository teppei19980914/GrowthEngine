# ユメログ (GrowthEngine) - Claude Code 運用ガイド

## プロジェクト概要

- **ユメログ** - Flutter マルチプラットフォームアプリ (StudyQualificationApplication の Flutter 移植版)
- Web 体験版: GitHub Pages (`https://teppei19980914.github.io/GrowthEngine/`)
- ネイティブ版 (Android/iOS/Windows等) も同一リポジトリで管理
- Drift ORM + Riverpod 状態管理

## 運用フロー

以下のフローで運用する。

### Claude Code が担当 (ステップ 1)

1. **プログラム修正**: `sonarcloud-reports/latest-report.txt` の指摘内容を読み込み、セキュリティを考慮したうえでソースコード修正。対応するテストコードも必ず追加・修正する
   - コミット & プッシュはユーザーが手動で実施（GitHub Actions の無料枠節約のため）

### ユーザーが手動で実施 (ステップ 2, 3)

2. **ローカル動作確認**: `run_windows.bat` で Windows ネイティブアプリを起動し動作確認
3. **コミット & プッシュ**: 修正完了後、main ブランチにコミット & プッシュする

### GitHub Actions が担当 (ステップ 4, 5, 6)

4. **テスト & デプロイ** (deploy.yml): push をトリガーに `flutter analyze` → `flutter test --coverage` → `flutter build web` → GitHub Pages デプロイ を自動実行
5. **SonarCloud 静的解析** (sonarcloud.yml): push をトリガーにテスト → SonarCloud Dart 解析 → レポートを `sonarcloud-reports/` に自動コミット
6. **公開**: デプロイ成功後、GitHub Pages に自動反映

### ユーザーが手動で実施 (ステップ 7)

7. **Web 動作確認**: ブラウザで体験版アプリの動作確認

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
- **sonarcloud.yml**: main push 時 → テスト → SonarCloud 解析 → レポート自動コミット
- **test.yml**: PR 時 → テスト（カバレッジ付き）のみ実行
- カバレッジレポートは各ワークフロー実行の Summary タブに出力される
- SonarCloud レポートは `sonarcloud-reports/latest-report.txt` に自動保存される

## 技術スタック

- Flutter (Dart) - Web ターゲット
- Drift (SQLite ORM) + drift_worker.js (Web WASM)
- flutter_riverpod (状態管理)
- fl_chart (グラフ)
- go_router (ルーティング)
- shared_preferences (設定永続化)
- SonarQube Cloud (静的コード解析・セキュリティ)
