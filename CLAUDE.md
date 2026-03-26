# ユメログ (GrowthEngine) - Claude Code 運用ガイド

## プロジェクト概要

- **ユメログ** - Flutter マルチプラットフォームアプリ (StudyQualificationApplication の Flutter 移植版)
- Web 体験版: GitHub Pages (`https://teppei19980914.github.io/GrowthEngine/`)
- ネイティブ版 (Android/iOS/Windows等) も同一リポジトリで管理
- Drift ORM + Riverpod 状態管理

## 運用フロー

以下のフローで運用する。

### Claude Code が担当 (ステップ 1)

1. **プログラム修正**: 以下のレポートを読み込み、問題を特定してソースコード修正。対応するテストコードも必ず追加・修正する
   - **静的解析**: `sonarcloud-reports/latest-report.txt` の指摘内容を読み込み、セキュリティを考慮して修正
   - **UIテスト失敗時**: `integration_test_reports/latest-report.txt` を読み込み、Failed Tests セクションを確認して該当ウィジェット/ページを修正
   - コミット & プッシュはユーザーが手動で実施（GitHub Actions の無料枠節約のため）

### ユーザーが手動で実施 (ステップ 2, 3)

2. **ローカル動作確認**: `run_windows.bat` で Windows アプリを起動し動作確認
3. **コミット & プッシュ**: 修正完了後、main ブランチにコミット & プッシュする

### GitHub Actions が担当 (ステップ 4, 5, 6)

4. **テスト & デプロイ** (deploy.yml): push をトリガーに `flutter analyze` → `flutter test --coverage` → `flutter build web` → GitHub Pages デプロイ を自動実行
5. **SonarCloud 静的解析** (sonarcloud.yml): push をトリガーにテスト → SonarCloud Dart 解析 → レポートを `sonarcloud-reports/` に自動コミット
6. **UIインテグレーションテスト** (integration_test.yml): push をトリガーに `flutter test integration_test/` → レポートを `integration_test_reports/latest-report.txt` に自動コミット
7. **公開**: デプロイ成功後、GitHub Pages に自動反映

### ユーザーが手動で実施 (ステップ 8)

8. **Web 動作確認**: ブラウザで体験版アプリの動作確認（UIテストで自動検証済みの場合は省略可）

## コミットルール

- ローカルでのテスト実行は不要（GitHub Actions に一任）
- テストコードの追加・修正を伴わないソースコード変更はコミットしない
- コミットメッセージは変更内容を端的に記述する

## デプロイ検証ルール

実装修正時は毎回以下のデプロイ検証を実施すること:

1. **`flutter analyze`** をローカルで実行し、静的解析エラーが0件であることを確認する
2. **インテグレーションテストへの影響確認**: UI変更時は `integration_test/app_test.dart` のテストが既存のFinderやナビゲーションフローに影響しないか確認する
3. **GoRouterシングルトン注意**: `app.dart` の `_router` はモジュールレベルシングルトンのため、テスト間でルート状態が漏洩する。インテグレーションテストでは `NavigationDestination` のインデックスまたはドロワー経由のナビゲーションを使用し、アイコンによる直接検索を避ける
4. **AppDrawerアイコン重複注意**: AppDrawerはScaffoldのwidgetツリーに常に存在するため、`find.byIcon()` でNavigationBarとAppDrawerの両方にマッチする。NavigationBar限定の検索には `find.descendant(of: find.byType(NavigationBar), ...)` を使用する

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
- **integration_test.yml**: main push 時 → UIインテグレーションテスト → レポート自動コミット
- **test.yml**: PR 時 → テスト（カバレッジ付き）のみ実行
- カバレッジレポートは各ワークフロー実行の Summary タブに出力される
- SonarCloud レポートは `sonarcloud-reports/latest-report.txt` に自動保存される
- UIテストレポートは `integration_test_reports/latest-report.txt` に自動保存される

## リリース前チェックリスト

実装完了後、コミット前に以下の3項目を必ず実施すること:

### 1. セキュリティチェック

- **XSS対策**: ユーザー入力をHTML/CSS/JSに埋め込む箇所は必ずサニタイズする（`_escapeHtml()`, `_sanitizeHexColor()` 等）
- **インジェクション対策**: Drift ORM のパラメータ化クエリを使用し、生SQLは禁止
- **入力バリデーション**: 全ダイアログの入力フィールドに適切なバリデーション（必須チェック、形式チェック、長さ上限）を設定する
- **インポート検証**: 外部JSON/ファイルの読み込み時はサイズ上限・型チェック・フォーマット検証を行う
- **機密情報**: API キー・シークレットをソースコードにハードコードしない。Firebase API Key は Web API Key として許容するが、サーバーキーは禁止

### 2. パフォーマンスチェック

- **N+1クエリ禁止**: ループ内でDB問い合わせしない。一括取得してからメモリ上でフィルタ/グルーピングする
- **CustomPainter最適化**: `Paint` オブジェクトはコンストラクタでキャッシュし、`paint()` 内でのインスタンス生成を最小化する
- **Provider設計**: 1つのウィジェットが watch する Provider は最小限に。頻繁に参照されるデータは合成 Provider にまとめる
- **RepaintBoundary**: 重い描画領域（ガントチャート、グラフ等）は `RepaintBoundary` で隔離する
- **非同期処理**: 独立した非同期操作は `Future.wait()` で並列化する

### 3. 単体テスト

- 新規・変更したロジックに対応するテストを必ず追加する
- `flutter analyze` でエラー0件を確認する
- `flutter test` で全テスト合格を確認する（テスト数の増減を確認）

## 技術スタック

- Flutter (Dart) - Web ターゲット
- Drift (SQLite ORM) + drift_worker.js (Web WASM)
- flutter_riverpod (状態管理)
- fl_chart (グラフ)
- go_router (ルーティング)
- shared_preferences (設定永続化)
- SonarQube Cloud (静的コード解析・セキュリティ)
