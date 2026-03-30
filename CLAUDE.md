# ユメログ (GrowthEngine) - Claude Code 運用ガイド

## プロジェクト概要

- **ユメログ** - Flutter マルチプラットフォームアプリ
- Web 体験版: GitHub Pages (`https://teppei19980914.github.io/GrowthEngine/`)
- Drift ORM + Riverpod 状態管理

## 運用フロー

1. Claude Code がソースコード修正 + テスト追加（`/fix-issue` スキル参照）
2. ユーザーが `run_windows.bat` で動作確認 → main にコミット & プッシュ
3. GitHub Actions が自動テスト → GitHub Pages デプロイ

## コミットルール

- テストコードの追加・修正を伴わないソースコード変更はコミットしない
- コミットメッセージは変更内容を端的に記述する
- コミット & プッシュはユーザーが手動で実施

## コミット前チェック（毎回必須）

実装完了後、コミット前に以下を必ず実施する。詳細手順は各スキルを参照。

1. **横展開チェック** — 同一パターンを `grep` で網羅検索し漏れなく対応
2. **セキュリティチェック** — XSS、インジェクション、バリデーション、機密情報
3. **パフォーマンスチェック** — N+1禁止、Paint キャッシュ、RepaintBoundary
4. **デプロイチェック** — `flutter analyze` → `flutter test` → `flutter build web` をローカルで実行し全て成功を確認
5. **単体テスト** — テスト数の増減を確認、旧ラベル文字列の残留を `grep` で検索

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
