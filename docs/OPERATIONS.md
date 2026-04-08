# ユメハシ 運用手順書

## 目次

1. [日常的な改修フロー](#1-日常的な改修フロー)
2. [バージョンアップ・リリース手順](#2-バージョンアップリリース手順)
3. [データベース変更手順](#3-データベース変更手順)
4. [ラベル・メッセージの修正](#4-ラベルメッセージの修正)
5. [ユーザーへの通知配信](#5-ユーザーへの通知配信)
6. [FAQ の運用](#6-faq-の運用)
7. [管理ファイル一覧](#7-管理ファイル一覧)
8. [Claude Code 設定（Skills / Hooks / Agents）](#8-claude-code-設定skills--hooks--agents)
9. [GitHub Actions（自動処理）](#9-github-actions自動処理)
10. [ストレステスト運用](#10-ストレステスト運用)
11. [外部サービス・コスト管理](#11-外部サービスコスト管理)
12. [セキュリティ運用](#12-セキュリティ運用)
13. [トラブルシューティング](#13-トラブルシューティング)
14. [インシデント対応手順](#14-インシデント対応手順)

---

## 1. 日常的な改修フロー

### ブランチ運用ルール

- **main への直接プッシュは禁止**。必ずブランチ → PR → マージの流れで行う
- ブランチ名: `feature/機能名` または `fix/修正内容`
- PR 作成時に CI が自動実行（テスト + バージョンチェック）
- CI 通過後にマージ → GitHub Pages に自動デプロイ

### 手順

```
1. ブランチを作成: git checkout -b feature/xxx
2. ソースコード修正 + 対応するテストコード追加・修正
3. ローカル確認: flutter analyze（エラー0件）
4. ローカル確認: run_windows.bat で動作確認
5. バージョン4点セットを更新（2. リリース手順 参照）
6. ブランチにコミット & プッシュ → main へ PR 作成
7. CI が テスト + バージョンチェック を自動実行
8. CI 通過後にマージ → GitHub Pages に自動デプロイ
9. ブラウザで https://teppei19980914.github.io/YumeHashi/ を動作確認
```

### コミットルール

- テストコードの追加・修正を伴わないソースコード変更はコミットしない
- コミットメッセージは変更内容を端的に記述する

### リリース前チェックリスト

コミット前に以下の5項目を必ず実施する:

1. **横展開チェック**: 同一パターンを `grep` で網羅検索し漏れなく対応
2. **セキュリティチェック**: XSS対策、インジェクション対策、入力バリデーション、インポート検証
3. **パフォーマンスチェック**: N+1クエリ禁止、CustomPainter最適化、Provider設計、RepaintBoundary
4. **デプロイチェック**: ローカルで GitHub Actions と同等の検証を実施（下記手順）
5. **単体テスト**: `flutter analyze` エラー0件、`flutter test` 全合格

### デプロイチェック手順

```bash
# Step 1: 静的解析
flutter analyze

# Step 2: 全テスト実行
flutter test

# Step 3: Web ビルド確認
flutter build web --release --base-href "/YumeHashi/"
```

**全て成功した場合のみコミット & プッシュする。**

---

## 2. バージョンアップ・リリース手順

### バージョン番号の規則（セマンティックバージョニング）

| 数字 | 名称 | いつ上げるか | 例 |
|---|---|---|---|
| **1**.0.0 | メジャー | 既存ユーザーに影響する破壊的変更 | データ形式変更、画面構成の大幅刷新 |
| 1.**0**.0 | マイナー | 新機能の追加（既存機能は壊れない） | 新画面追加、既存機能の拡張 |
| 1.0.**0** | パッチ | バグ修正・軽微な改善（機能追加なし） | 表示崩れ修正、文言修正 |

### リリース時の必須更新ファイル（4点セット）

**1つでも漏れると不具合が発生する。必ず全て同時に更新すること。**

| # | ファイル | 更新内容 |
|---|---|---|
| 1 | `pubspec.yaml` | `version:` フィールドを更新 |
| 2 | `lib/app_version.dart` | `appVersion` 定数 + `releaseHistory` 先頭にエントリ追加 |
| 3 | `assets/announcements.json` | 受信ボックス通知エントリを追加 |
| 4 | `test/pages/settings_page_test.dart` | バージョン文字列をテスト内で更新 |

### リリース手順

```bash
# 1. 上記4ファイルを更新
# 2. 確認
flutter analyze
flutter test
# 3. コミット & プッシュ
git add pubspec.yaml lib/app_version.dart assets/announcements.json test/
git commit -m "v1.2.0 リリース"
git push origin main
```

### 確認コマンド（バージョン文字列の漏れチェック）

```bash
# 旧バージョンが残っていないか確認
grep -rn '1.0.2' lib/ test/ pubspec.yaml assets/
```

---

## 3. データベース変更手順

### **最重要ルール: カラム追加時は5点セットで変更する**

テーブルにカラムを追加する際、以下を1つでも漏らすとデータ消失が発生する。

| # | 対象 | 変更内容 |
|---|---|---|
| 1 | テーブル定義 | `lib/database/tables/` に新カラム追加 |
| 2 | スキーマバージョン | `lib/database/app_database.dart` の `schemaVersion` をインクリメント |
| 3 | マイグレーション | `onUpgrade` に `ALTER TABLE ... ADD COLUMN` を追加 |
| 4 | モデル | `lib/models/` にフィールド追加（constructor, copyWith, toMap, fromMap） |
| 5 | エクスポート | `lib/services/data_export_service.dart` の変換メソッドに新カラム追加 |

### マイグレーション手順

```dart
// app_database.dart
@override
int get schemaVersion => 8;  // ← インクリメント

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    // ... 既存のマイグレーション ...
    if (from < 8) {  // ← 新しいバージョン番号
      await customStatement(
        'ALTER TABLE dreams ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      ).catchError((_) {/* カラムが既に存在する場合は無視 */});
    }
  },
);
```

### コード生成

テーブル定義変更後は必ず Drift のコード生成を実行する:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 過去のインシデント

- **v1.2.0 開発中**: Dream テーブルに `sortOrder` を追加した際、マイグレーション未定義によりDBが再作成され、全ユーザーデータが消失。クラウドバックアップから復元。

---

## 4. ラベル・メッセージの修正

### 修正対象ファイル

**lib/l10n/app_labels.dart**（約1,100定数）

### 主なカテゴリ

| カテゴリ | プレフィックス | 例 |
|---|---|---|
| ページ名 | `page` | `pageHome`, `pageGoals` |
| ボタン | `btn` | `btnCancel`, `btnDelete` |
| 夢/目標/タスク/書籍 | `dream`/`goal`/`task`/`book` | 各種 |
| FAQ | `helpFaq` | `helpFaqDreamGoalTaskQ` / `A` |
| チュートリアル | `tutorial` | `tutorialAddDream` |

### 注意事項

- テストコード内でラベル文字列を直接参照している場合はテストも修正する
- `grep -rn '旧文言' lib/ test/` で旧文言の残留を必ず確認する

---

## 5. ユーザーへの通知配信

### 管理ファイル: `assets/announcements.json`

### フィールド仕様

| フィールド | 必須 | 形式 | 説明 |
|---|---|---|---|
| `dedup_key` | 必須 | 文字列 | 重複排除キー |
| `date` | 任意 | `yyyy-MM-dd` | 配信日（未来日付は予約通知） |
| `title` | 必須 | 文字列 | 通知の件名 |
| `message` | 必須 | 文字列 | 通知の本文 |

### 初回アクセスユーザーへの配慮

初回アクセス時は最新の1件のみ未読表示される。過去の通知は既読状態でDBに登録される。

### 操作一覧

| やりたいこと | 操作 |
|---|---|
| お知らせ配信 | JSON にエントリ追加 → コミット & プッシュ |
| お知らせ削除 | JSON からエントリ削除 → コミット & プッシュ |
| リリース通知 | `app_version.dart` 更新 + JSON にエントリ追加 |

---

## 6. FAQ の運用

### 管理ファイル

- ラベル: `lib/l10n/app_labels.dart`（`helpFaq` プレフィックス）
- 表示: `lib/dialogs/help_dialog.dart`（`_FaqTab` クラス）

### カテゴリ一覧

| カテゴリ | FAQ数 | 内容 |
|---|---|---|
| 基本的な使い方 | 6件 | 夢/目標/タスクの違い、活動予定、星座、書籍 |
| データ管理 | 5件 | 保存先、クラウド/ブラウザ、バックアップ、端末移行 |
| プラン・料金 | 3件 | 契約、制限解除、解約 |
| 問い合わせ・感想 | 3件 | 問い合わせ方法、感想の送り方、どんな感想を送るか |
| 端末・環境 | 2件 | スマホ対応、ブラウザ対応 |
| その他 | 3件 | 退会、チュートリアル、実績、開発者の思い |

### FAQ 追加手順

1. `app_labels.dart` に Q/A ラベルを追加
2. `help_dialog.dart` の `_faqs` リストに `_FaqItem` を追加（`category` 必須）
3. 検索用 `keywords` を設定

### FAQ の記述ルール

- **冒頭で質問に端的に回答**（はい/いいえ、または操作手順の要約）
- **補足情報は改行で区切って後に記載**
- UI要素の参照は現在のUI（`⋮` メニュー、`+` ボタン等）に合わせる

---

## 7. 管理ファイル一覧

| ファイル | 役割 | 更新タイミング |
|---|---|---|
| `pubspec.yaml` | バージョン番号 | リリース時 |
| `lib/app_version.dart` | バージョン + リリース履歴 | リリース時 |
| `lib/l10n/app_labels.dart` | 全ラベル・メッセージ | テキスト修正時 |
| `assets/announcements.json` | 開発者通知 | お知らせ配信時 |
| `lib/database/app_database.dart` | DB スキーマ + マイグレーション | DB変更時 |
| `lib/services/data_export_service.dart` | エクスポート/インポート変換 | DB変更時 |
| `CLAUDE.md` | Claude Code 運用ガイド | 開発ルール変更時 |
| `docs/INFRASTRUCTURE.md` | インフラ構成・コスト | インフラ変更時 |
| `docs/OPERATIONS.md` | 本手順書 | 運用手順変更時 |
| `docs/REQUIREMENTS.md` | 要件定義書 | 機能追加時 |
| `docs/SPECIFICATION.md` | 仕様書 | 画面仕様変更時 |
| `docs/DESIGN.md` | 設計書 | アーキテクチャ変更時 |

---

## 8. Claude Code 設定（Skills / Hooks / Agents）

### Skills（スキル）

| コマンド | 用途 |
|---|---|
| `/fix-issue` | SonarCloud/UIテストレポートから問題を修正 |
| `/release` | バージョンアップ・リリース作業を実行 |
| `/check-deploy` | GitHub Actionsのデプロイ失敗を調査・修正 |
| `/update-labels` | ラベル・メッセージの変更と横展開 |

### Hooks（自動処理）

| Hook | トリガー | 動作 |
|---|---|---|
| PostToolUse (Write/Edit) | ファイル編集後 | `dart format --fix` を自動実行 |
| Stop (command) | セッション終了時 | `flutter analyze` → `flutter test` → ハードコード日本語検出 |
| Stop (prompt) | セッション終了時 | 横展開・セキュリティ・パフォーマンス・テスト整合性を最終チェック |

### Agents（並行レビュー）

| Agent | 用途 |
|---|---|
| security-reviewer | セキュリティ観点でコードレビュー |
| performance-reviewer | パフォーマンス観点でコードレビュー |
| label-checker | ハードコード日本語文字列の検出 |

---

## 9. GitHub Actions（自動処理）

### test.yml（PR 時 — テスト + バージョンチェック）

```
┌─ lint-and-test ──────────────────────────────┐
│  flutter analyze → flutter test --coverage    │
└──────────────────────────────────────────────┘
┌─ version-check ──────────────────────────────┐
│  1. pubspec.yaml のバージョンが main と異なるか │
│  2. app_version.dart の appVersion が一致するか │
│  3. releaseHistory にエントリがあるか           │
│  4. announcements.json にエントリがあるか       │
│  → 1つでも漏れがあれば CI 失敗（マージ不可）     │
└──────────────────────────────────────────────┘
```

**バージョン4点セットの更新漏れは CI が自動検知し、PR のマージを阻止する。**

### deploy.yml（main push 時）

```
flutter analyze → flutter test --coverage → flutter build web → GitHub Pages デプロイ
```

### stress-test.yml（毎週日曜 12:00 JST）

```
データ件数テスト → 画面描画テスト → 同時アクセステスト → 結果コミット → 閾値超過時にIssue起票
```

---

## 10. ストレステスト運用

### パフォーマンス閾値: 全操作 1秒以内

| テスト種別 | ファイル | テスト数 |
|---|---|---|
| データ件数 | `test_stress/data_volume_stress_test.dart` | 16件 |
| 画面描画 | `test_stress/rendering_stress_test.dart` | 10件 |
| 同時アクセス | `test_stress/concurrent_access_stress_test.dart` | 10件 |

### よくあるボトルネックと改善パターン

| パターン | 原因 | 改善方法 |
|---|---|---|
| INSERT/DELETEが遅い | ループ内で1件ずつDB操作 | `db.batch()` でバッチ処理 |
| N+1クエリ | 目標ごとにタスクを個別取得 | 一括取得して Map 化 |
| CustomPainter が遅い | `paint()` 内で Paint 生成 | コンストラクタでキャッシュ |

---

## 11. 外部サービス・コスト管理

詳細は [INFRASTRUCTURE.md](INFRASTRUCTURE.md) を参照。

### コスト概要

**現在のコスト: 0円（全サービス無料枠内）**

| サービス | 用途 | 無料枠 | コスト発生閾値 |
|---|---|---|---|
| Firebase Auth | 認証 | 50,000回/月 | 超大規模時のみ |
| Firestore | データ同期 | 書込 20,000回/日 | **DAU 3,000人超** |
| GitHub Pages | ホスティング | 1GB帯域/月 | 超大規模時のみ |
| GitHub Actions | CI/CD | 2,000分/月 | 超大規模時のみ |
| Google Apps Script | Stripe プロキシ等 | 1000万回/月 | 実質無制限 |
| GitHub Gist API | リモート設定 | 60回/時 | 認証トークン追加で解消可 |

### Firestore の書き込み発生タイミング

1. アプリ起動時（タイムスタンプ比較で1回）
2. データ変更時（3秒デバウンス + ハッシュ比較後に1回）
3. アプリ離脱時（未同期データがあれば1回）

### 安全策（実装済み）

- 3秒デバウンス（連続操作を1回にまとめる）
- SHA-256 ハッシュ比較（データ未変更なら書き込みスキップ）
- 空データによるクラウドバックアップ上書き防止

---

## 12. セキュリティ運用

### 実施済み対策

| 対策 | 内容 | 対象ファイル |
|---|---|---|
| サブスク検証必須化 | URLパラメータだけでは有効化不可、サーバー検証必須 | `main.dart` |
| 空データ上書き防止 | ローカルDBが空の場合、クラウドを上書きしない | `sync_manager.dart` |
| 入力バリデーション | XSSサニタイズ、パラメータ化クエリ | 各ダイアログ・サービス |
| インポート検証 | JSON構造・型の検証後にDBインサート | `data_export_service.dart` |

### サブスクリプション有効化の正規フロー

```
ユーザーが「プランのアップグレード」をタップ
    ↓
Apps Script 経由で Stripe Checkout URL を取得
    ↓
Stripe 決済ページで支払い完了
    ↓
アプリに戻る → verifySubscription() でサーバー検証
    ↓
Stripe が active=true を返した場合のみプレミアム有効化
```

**URLパラメータ `?subscription=success` だけではプレミアム化しない。**

### プレミアム判定の5つの経路

| 経路 | 判定方法 | 対象 |
|---|---|---|
| 非Web（ローカル実行） | `!isTrialMode` | 開発者 |
| 招待コード | `_invitePremium`（remote config） | 招待ユーザー |
| Stripe 契約 | `_subscriptionPremium`（サーバー検証） | 契約者 |
| 無料トライアル | `_trialPremium`（7日間） | 体験ユーザー |
| 開発者メール | `_developerMode`（Firebase Auth） | 開発者 |

---

## 13. トラブルシューティング

### デプロイ失敗

```bash
# 失敗ログを取得
gh run list --limit 1
gh run view <RUN_ID> --log-failed

# ローカルで再現・修正
flutter analyze
flutter test
```

### ポート占有で run_windows.bat が起動しない

```bash
# ポート使用状況を確認
netstat -ano | findstr ":8081"

# プロセスを特定・終了
taskkill //PID <PID> //F

# それでも解消しない場合はポート番号を変更（run_windows.bat）
```

### モバイルブラウザで更新が反映されない

- Riverpod の状態更新が `ref.invalidateSelf()` を使用しているか確認
- 複数のプロバイダメソッドを連続呼び出ししていないか確認（一括更新に統合する）
- WASM SQLite の非同期タイミングが原因のレースコンディションを疑う

### データが消えた

1. 設定 → 「クラウドからデータを復元」を試行（メール連携済みの場合）
2. エクスポートファイルがあれば「データを読み込む」で復元
3. 原因がDBマイグレーション漏れの場合は「3. データベース変更手順」を参照

---

## 14. インシデント対応手順

### データ消失インシデント

```
1. 影響範囲の特定
   - 全ユーザー影響か、特定ユーザーか
   - DBマイグレーション漏れか、同期バグか

2. 原因の特定
   - app_database.dart の schemaVersion とマイグレーション定義を確認
   - sync_manager.dart の空データ上書き防止が機能しているか確認

3. 復旧
   - Firestore にバックアップが残っていれば復元
   - マイグレーション修正をデプロイ後、ユーザーに「クラウドから復元」を案内

4. 再発防止
   - 「3. データベース変更手順」の5点セットを遵守
   - テストで sortOrder 等の往復を検証
```

### サブスク不正利用の検知

```
1. Stripe ダッシュボードで実契約状態を確認
2. verifySubscription() のログを確認
3. 必要に応じて Apps Script 側で userKey をブロック
```

### GitHub Gist API レート制限超過

```
1. 一時的な影響: リモート設定の取得失敗（キャッシュにフォールバック）
2. 恒久対応: GitHub Personal Access Token を設定して認証リクエストに変更（5,000回/時）
```

---

## 更新履歴

| 日付 | 内容 |
|---|---|
| 2026-04-07 | v2.0.1 対応: CIワークフロー (`.github/workflows/test.yml`) のバージョンチェックに post-merge 競合回避ロジックを追加（PR の HEAD がすでに main にマージ済みの場合はスキップ） |
| 2026-04-08 | v2.1.0 対応: 既読通知・完了タスクの30日自動削除ポリシーを導入。「13. トラブルシューティング」に「データが勝手に消えた」項目追加予定。v2.0.2 scope（起動時パフォーマンス改善）も統合 |
| 2026-04-07 | v2.0.0 対応: アプリ名「ユメハシ」への正式移行に伴うメジャーバージョンアップ手順を反映 |
| 2026-04-05 | 全面改訂（v1.2.0）: DB変更手順、FAQ運用、コスト管理、セキュリティ運用、インシデント対応を追加 |
| 2026-04-03 | 初版作成 |
