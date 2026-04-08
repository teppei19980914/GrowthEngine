# ユメハシ 設計書

## 1. アーキテクチャ概要

```
┌─────────────────────────────────────────────────┐
│                    UI Layer                      │
│  Pages → Dialogs → Widgets → CustomPainters      │
├─────────────────────────────────────────────────┤
│               State Management                   │
│          Riverpod (Providers/Notifiers)           │
├─────────────────────────────────────────────────┤
│                Service Layer                     │
│  DreamService, GoalService, TaskService, etc.    │
├─────────────────────────────────────────────────┤
│                  Data Layer                      │
│     Drift ORM (DAOs) → SQLite WASM (Local)       │
│     FirestoreSyncService → Firestore (Cloud)     │
├─────────────────────────────────────────────────┤
│              External Services                   │
│  Firebase Auth / Stripe (via Apps Script) /       │
│  GitHub Gist API / GitHub Pages                  │
└─────────────────────────────────────────────────┘
```

### 設計パターン

- **MVVM**: Riverpod Provider が ViewModel 相当
- **Repository**: DAO がデータアクセスを抽象化
- **Service Layer**: ビジネスロジックを Service に集約

## 2. ディレクトリ構成

```
lib/
├── app.dart                 # アプリケーションルート（ルーティング、AppShell）
├── app_version.dart         # バージョン情報・リリース履歴
├── main.dart                # エントリポイント（サブスク検証、Firebase初期化）
├── l10n/
│   └── app_labels.dart      # 全UIテキスト定義（約700定数）
├── data/                    # テンプレートデータ（夢/目標/タスク/星座）
├── database/
│   ├── app_database.dart    # Drift DB定義（schemaVersion: 8）
│   ├── daos/                # Data Access Objects（6 DAO）
│   └── tables/              # テーブル定義（6テーブル）
├── models/                  # データモデル（8ファイル）
├── services/                # ビジネスロジック（34ファイル）
├── providers/               # Riverpod Provider（11ファイル）
├── pages/                   # 画面（8ファイル）
├── dialogs/                 # ダイアログ（21ファイル）
├── widgets/                 # 再利用可能ウィジェット
│   ├── gantt/               # 活動予定チャート
│   ├── navigation/          # ナビゲーション
│   ├── notification/        # 受信ボックス
│   ├── milestone/           # 実績
│   ├── constellation/       # 星座
│   ├── contact/             # お問い合わせ
│   ├── premium/             # プレミアムゲート
│   ├── stats/               # 統計
│   ├── tutorial/            # チュートリアル
│   └── web/                 # Web体験版バナー
└── theme/
    └── app_theme.dart       # Catppuccin テーマ定義
```

## 3. データモデル設計

### ER図

```
Dream (夢)
  │ 1:N     sortOrder で並び順を管理
  ├── Goal (目標)
  │     │ 1:N     sortOrder で並び順を管理
  │     └── Task (タスク)
  │           │ 1:N
  │           └── StudyLog (活動ログ)
  │
  └── (カテゴリ別 星座紐づけ)

Book (書籍)
  │ 1:1
  └── Task (読書スケジュール, goalId = '__books__')

Notification (通知)
  └── 独立エンティティ（system / achievement / reminder）
```

### テーブル定義

| テーブル | PK | 主要カラム | 備考 |
|---|---|---|---|
| Dreams | id (UUID) | title, description, why, category, **sortOrder**, createdAt, updatedAt | v8 で sortOrder 追加 |
| Goals | id (UUID) | dreamId, what, whenTarget, whenType, how, color, **sortOrder**, createdAt, updatedAt | v7 で sortOrder 追加 |
| Tasks | id (UUID) | goalId, title, startDate, endDate, status, progress, memo, bookId, order | |
| Books | id (UUID) | title, status, category, why, description, summary, impressions, startDate, endDate, progress, createdAt, **updatedAt** | |
| StudyLogs | id (UUID) | taskId, studyDate, durationMinutes, memo, taskName | |
| Notifications | id (UUID) | notificationType, title, message, isRead, **dedupKey**, createdAt | |

### DBマイグレーション履歴

| Version | 変更内容 |
|---|---|
| 1 | 初期スキーマ（Goals, Tasks, Books, StudyLogs, Notifications） |
| 2 | Dreams テーブル追加、Goals に dreamId 追加 |
| 3 | Dreams に why 追加 |
| 4 | Books に why, description 追加 |
| 5 | Books に category 追加 |
| 6 | Dreams に category 追加 |
| 7 | Goals に sortOrder 追加 |
| 8 | Dreams に sortOrder 追加 |

## 4. 状態管理設計

### Provider 一覧

| Provider | 種別 | 役割 |
|---|---|---|
| databaseProvider | Provider | DB インスタンス |
| dreamListProvider | AsyncNotifier | 夢の一覧管理（CRUD + reorder） |
| goalListProvider | AsyncNotifier | 目標の一覧管理（CRUD + reorder） |
| goalProgressProvider | FutureProvider | 目標別タスク進捗（全タスク一括取得） |
| bookListProvider | AsyncNotifier | 書籍の一覧管理（CRUD + 一括更新） |
| sortedBookListProvider | FutureProvider | ソート済み書籍一覧 |
| bookSortOrderProvider | StateProvider | 書籍ソート基準 |
| ganttViewStateProvider | Notifier | 活動予定表示状態 |
| ganttTasksProvider | FutureProvider | フィルタ済みタスク一覧 |
| dashboardLayoutProvider | AsyncNotifier | ダッシュボードレイアウト |
| constellationProgressProvider | FutureProvider | 星座進捗 |
| allLogsProvider | FutureProvider | 全活動ログ（キャッシュ共有） |
| unreadCountProvider | FutureProvider | 未読通知数 |

### 状態管理ルール

- DB操作後は `ref.invalidateSelf()` で `build()` を再実行（手動 `state = AsyncData(...)` 禁止）
- 1つの編集操作は1回のDB更新 + 1回の invalidate で完結させる（レースコンディション防止）
- 頻繁に参照されるデータは合成 Provider にまとめる
- DB一括取得 → メモリ上でフィルタ/グルーピング（N+1禁止）

## 5. 活動予定チャート設計

### スクロール方式

```
┌─────────┬──────────────────────────────┐
│ 固定     │ ← headerHorizontalCtrl →     │ ヘッダー
├─────────┼──────────────────────────────┤
│ ↕       │ ← horizontalController →     │
│ label   │                              │ ボディ
│ Ctrl    │ ↕ verticalController         │
└─────────┴──────────────────────────────┘
```

### 描画最適化

- `_gridPaint`, `_todayFillPaint` をコンストラクタでキャッシュ
- 今日の表示: 半透明帯（`drawRect` + `pixelsPerDay` 幅）
- `shouldRepaint` で不要な再描画を抑制
- `RepaintBoundary` でヘッダー・左列・ボディを独立リペイント

## 6. セキュリティ設計

| 対策 | 実装 |
|---|---|
| XSS | `_escapeHtml()`, `_sanitizeHexColor()` でサニタイズ |
| SQLインジェクション | Drift ORM パラメータ化クエリのみ |
| 入力バリデーション | 全ダイアログに `validator` 設定 |
| インポート検証 | 10MBサイズ上限 + 型チェック |
| サブスク検証 | サーバー検証必須（URLパラメータだけでは有効化不可） |
| 空データ上書き防止 | `_executeUpload()` で全エンティティ0件なら同期スキップ |
| 認証 | Firebase Auth（匿名 + メール連携） |

## 7. 同期設計

### クラウド同期フロー

```
データ変更 → requestSync() → 3秒デバウンス
  ↓
exportData() → SHA-256ハッシュ計算
  ↓
前回ハッシュと比較 → 変更なし: スキップ
  ↓                   変更あり ↓
                 全エンティティ0件チェック → 空: スキップ（上書き防止）
                                           ↓ データあり
                                      Firestore にアップロード
```

### 初回アクセス時の通知同期

```
announcements.json 読み込み
  ↓
DB にシステム通知が0件（初回）? → 最新1件のみ未読、残りは既読でDB登録
                                → 既存ユーザー: 新規分を全て未読で追加
```

## 8. CI/CD 設計

### GitHub Actions ワークフロー

| ワークフロー | トリガー | 処理 |
|---|---|---|
| deploy.yml | main push | analyze → test → build → deploy |
| stress-test.yml | 毎週日曜 / 手動 | 3種ストレステスト → 結果コミット → Issue起票 |

### Claude Code Hooks

| Hook | タイミング | 内容 |
|---|---|---|
| PostToolUse | ファイル編集後 | `dart format --fix` |
| Stop (command) | セッション終了 | analyze + test + ハードコード検出 |
| Stop (prompt) | セッション終了 | 横展開・セキュリティ・パフォーマンス・テストのAIチェック |

## 9. テスト設計

### テスト構成（826テスト + 36ストレステスト）

```
test/                        # 単体・ウィジェットテスト（826件）
├── models/                  # モデルの単体テスト
├── database/                # DAO の単体テスト
├── services/                # サービスの単体テスト
├── providers/               # Provider・ソートのテスト
├── pages/                   # ページの Widget テスト
├── dialogs/                 # ダイアログの Widget テスト
├── widgets/                 # カスタムウィジェットのテスト
├── helpers/                 # テストユーティリティ
└── widget_test.dart         # スモークテスト

test_stress/                 # ストレステスト（36件、CI分離）
├── data_volume_stress_test.dart     # データ件数（16件）
├── rendering_stress_test.dart       # 画面描画（10件）
└── concurrent_access_stress_test.dart # 同時アクセス（10件）
```

### テストルール

- テスト環境では `disableInboxCheckForTest()` を呼ぶ（非同期ハング防止）
- Drift の `isNull`/`isNotNull` は flutter_test と競合するため `hide`
- GoRouter はモジュールレベルシングルトン。テストではドロワー経由ナビゲーション使用
- ラベル変更時はテストの旧文言を `grep` で検索し全て更新
- エクスポート/インポートテストで sortOrder の往復を検証

## 更新履歴

| 日付 | 内容 |
|---|---|
| 2026-04-08 | v2.1.0 反映: (a)`lib/services/startup_premium_sync.dart` を追加し `runApp()` 前に `applyCachedPremiumState()` を呼ぶ設計。(b)`lib/services/data_retention_service.dart` を追加し、`NotificationDao.deleteReadNotificationsOlderThan()` と `TaskDao.deleteCompletedOlderThan()` を起動時に呼び出してデータを物理削除（保持期間 30 日）。(c)`BookSortOrderNotifier` / `GanttShowCompletedNotifier` を `NotifierProvider` へ変更し `SharedPreferences` で永続化。(d)`ganttTasksProvider` に完了タスク除外フィルタを追加（デフォルトで除外）。(e)外部通信は `addPostFrameCallback` で遅延実行。`web/index.html` に preconnect / preload 追加。**(f) クラウド同期コスト最適化**: `lib/services/sync_payload_codec.dart` を新設し `gz1:` プレフィックスによる format バージョニングで gzip + Base64 圧縮。`DataExportService.exportDataCompact()` を追加し sync 経路のみインデントなし JSON を使用（ローカルファイル書き出しは従来どおり整形済み）。`SyncManager` のデバウンスを 3 秒 → 5 秒に拡大、アップロード前にペイロードサイズを監視（900 KB 超で warning log）。format 1（legacy プレーン JSON）も透過的に読み込むため既存ユーザーのデータは無傷 |
| 2026-04-07 | v2.0.1 反映: `NotificationService.syncSystemNotificationsFromJson` の仕様を変更。announcements.json を「受信ボックスの唯一のソース」とし、JSON から削除された dedup_key を持つシステム通知は DB からも除去する（重複告知の解消）。`NotificationDao.deleteByTypeWhereDedupKeyNotIn` を追加 |
| 2026-04-07 | v2.0.0 反映: アプリ名「ユメハシ」への正式移行。対応プラットフォームを Web / Windows に限定し、Android / iOS / macOS / Linux のビルド設定を削除。`buildBackupFileName()` ヘルパーを `data_export_service.dart` に追加 |
| 2026-04-05 | v1.2.0 反映: 状態管理ルール追加、同期設計、セキュリティ強化、DBマイグレーション履歴、テスト数更新 |
| 2026-04-01 | 初版作成（v1.0.0） |
