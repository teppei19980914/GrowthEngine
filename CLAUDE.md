# ユメハシ (YumeHashi) - Claude Code 運用ガイド

## プロジェクト概要

- **ユメハシ** - Flutter アプリ（対応プラットフォーム: Web / Windows）
- Web 体験版: GitHub Pages (`https://teppei19980914.github.io/YumeHashi/`)
- Drift ORM + Riverpod 状態管理

## 運用フロー

1. `feature/*` または `fix/*` ブランチを作成して開発
2. Claude Code がソースコード修正 + テスト追加（`/fix-issue` スキル参照）
3. ユーザーが `run_windows.bat` で動作確認
4. **リリース前にバージョン4点セットを更新**（pubspec.yaml / app_version.dart / announcements.json / テスト）
5. main へ PR 作成 → CI がテスト + バージョンチェックを自動実行
6. CI 通過後にマージ → GitHub Pages に自動デプロイ

## コミットルール

- テストコードの追加・修正を伴わないソースコード変更はコミットしない
- コミットメッセージは変更内容を端的に記述する
- **main への直接プッシュは禁止。必ず PR 経由でマージする**
- main ブランチでファイル編集しようとすると **PreToolUse Hook が自動ブロック** する
- ブロックされた場合、`git checkout -b feature/xxx` でブランチを作成してから開発を再開する

## コミット前チェック（毎回必須）

実装完了後、コミット前に以下を必ず実施する。詳細手順は各スキルを参照。

1. **横展開チェック** — 以下を必ず実施:
   - `grep -rn '旧文言' lib/ test/` で旧文言の残留を検索（0件であること）
   - `replace_all` 実行後は意図しない箇所が置換されていないか確認
   - `app_labels.dart` 編集後は `grep -rn 'ガントチャート' lib/` で禁止語の混入を確認
2. **セキュリティチェック** — XSS、インジェクション、バリデーション、機密情報
3. **パフォーマンスチェック** — N+1禁止、Paint キャッシュ、RepaintBoundary
4. **デプロイチェック** — `flutter analyze` → `flutter test` → `flutter build web` をローカルで実行し全て成功を確認
5. **単体テスト** — テスト数の増減を確認、旧ラベル文字列の残留を `grep` で検索
6. **ドキュメント最新化** — 変更内容に応じて以下を必ず最新化する:
   - `docs/REQUIREMENTS.md` — 機能要件・非機能要件の追加・変更
   - `docs/SPECIFICATION.md` — 画面仕様・受信ボックス・体験版制限の変更
   - `docs/DESIGN.md` — アーキテクチャ・データモデル・Provider・テスト構成の変更
   - `docs/OPERATIONS.md` — 運用手順・リリース手順・トラブルシューティングの変更
   - `docs/INFRASTRUCTURE.md` — インフラ構成・外部サービス・コストの変更

## テスト注意事項

- Drift の `isNull`/`isNotNull` は flutter_test と競合するため `hide` する
- GoRouter はモジュールレベルシングルトン。テストではドロワー経由ナビゲーションを使用
- AppDrawer のアイコン検索は `find.descendant(of: find.byType(NavigationBar), ...)` を使用
- テスト環境では `disableInboxCheckForTest()` を呼ぶ（非同期ハング防止）

## Claude Code レベル最適化ルール

各レベルの構成を変更する際は、以下の最適化を毎回実施する:

- **CLAUDE.md**: 150行以内を維持。詳細手順は Skills に移行し、ここにはルールの要約のみ残す
- **Skills**: 繰り返し使う作業手順を配置。CLAUDE.md と重複する詳細は Skills 側に集約
- **Hooks**: 自動化可能な品質チェックを追加。手動で繰り返している作業があれば Hook 化を検討
- **Agents**: 独立して並行実行できるレビュー作業を配置

## 技術スタック

- Flutter (Dart) - Web ターゲット
- Drift (SQLite ORM) + drift_worker.js (Web WASM)
- flutter_riverpod (状態管理)
- fl_chart (グラフ)
- go_router (ルーティング)
- shared_preferences (設定永続化)
- SonarQube Cloud (静的コード解析・セキュリティ)
