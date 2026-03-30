# ユメログ 設計書

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
│     Drift ORM (DAOs) → SQLite (Local)            │
│     FirestoreSyncService → Firestore (Cloud)     │
└─────────────────────────────────────────────────┘
```

### 設計パターン

- **MVVM**: Model-View-ViewModel（Riverpod Provider がViewModel相当）
- **Repository**: DAO がデータアクセスを抽象化
- **Service Layer**: ビジネスロジックをServiceに集約

## 2. ディレクトリ構成

```
lib/
├── app.dart                 # アプリケーションルート（ルーティング、AppShell）
├── app_version.dart         # バージョン情報・リリース履歴
├── main.dart                # エントリポイント
├── l10n/
│   └── app_labels.dart      # 全UIテキスト定義（約550定数）
├── data/
│   ├── announcements.dart   # 開発者通知定数
│   ├── constellations.dart  # 星座定義データ
│   ├── dream_templates.dart # 夢テンプレート
│   ├── goal_templates.dart  # 目標テンプレート
│   └── task_templates.dart  # タスクテンプレート
├── database/
│   ├── app_database.dart    # Drift データベース定義
│   ├── daos/                # Data Access Objects（6ファイル）
│   └── tables/              # テーブル定義（6ファイル）
├── models/                  # データモデル（8ファイル）
├── services/                # ビジネスロジック（30ファイル）
├── providers/               # Riverpod Provider（11ファイル）
├── pages/                   # 画面（8ファイル）
├── dialogs/                 # ダイアログ（21ファイル）
├── widgets/                 # 再利用可能ウィジェット
│   ├── gantt/               # スケジュール（ガントチャート）
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
  │ 1:N
  ├── Goal (目標)
  │     │ 1:N
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

| テーブル | PK | 主要カラム | 関連 |
|---|---|---|---|
| Dreams | id (UUID) | title, description, why, category | → Goals |
| Goals | id (UUID) | dreamId, what, whenTarget, whenType, how, color, sortOrder | Dreams → Goals → Tasks |
| Tasks | id (UUID) | goalId, title, startDate, endDate, status, progress, memo, bookId | Goals → Tasks → StudyLogs |
| Books | id (UUID) | title, status, category, why, description, summary, impressions, startDate, endDate, progress | → Tasks (schedule) |
| StudyLogs | id (UUID) | taskId, studyDate, durationMinutes, memo, taskName | Tasks → StudyLogs |
| Notifications | id (UUID) | notificationType, title, message, isRead, dedupKey | 独立 |

## 4. 状態管理設計

### Provider 一覧

| Provider | 種別 | 役割 |
|---|---|---|
| databaseProvider | Provider | DB インスタンス |
| dreamListProvider | AsyncNotifier | 夢の一覧管理 |
| goalListProvider | AsyncNotifier | 目標の一覧管理 |
| goalProgressProvider | FutureProvider | 目標別タスク進捗（全タスク一括取得） |
| bookListProvider | AsyncNotifier | 書籍の一覧管理 |
| ganttViewStateProvider | Notifier | スケジュール表示状態（モード/日付範囲） |
| ganttTasksProvider | FutureProvider | フィルタ済みタスク一覧 |
| dashboardLayoutProvider | AsyncNotifier | ダッシュボードレイアウト |
| constellationProgressProvider | FutureProvider | 星座進捗 |
| allLogsProvider | FutureProvider | 全活動ログ |
| unreadCountProvider | FutureProvider | 未読通知数 |

### 状態管理ルール

- 1ウィジェットが watch する Provider は最小限にする
- 頻繁に参照されるデータは合成 Provider にまとめる
- DB一括取得 → メモリ上でフィルタ/グルーピング（N+1禁止）

## 5. スケジュール（ガントチャート）設計

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

- **共有ScrollController方式**: ヘッダー/左列がボディのスクロールに同期
- **NeverScrollableScrollPhysics**: 全ScrollView のphysicsを無効化
- **_onPointerSignal**: マウスホイール→横、Shift+ホイール→縦
- **onPanUpdate**: タッチドラッグで両方向スクロール
- **RepaintBoundary**: ヘッダー・左列・ボディを独立リペイント

### 描画最適化

- `_gridPaint`, `_todayPaint` をコンストラクタでキャッシュ
- `shouldRepaint` で不要な再描画を抑制
- タイムライン範囲はタスクの開始日〜終了日のみで計算（マイルストーン除外）

## 6. セキュリティ設計

| 対策 | 実装 |
|---|---|
| XSS | `_escapeHtml()`, `_sanitizeHexColor()` でHTML/CSS出力をサニタイズ |
| SQLインジェクション | Drift ORM のパラメータ化クエリのみ使用 |
| 入力バリデーション | 全ダイアログに `validator` 設定 |
| インポート検証 | JSONインポート時に10MBサイズ上限 + 型チェック |
| 認証 | Firebase Auth（匿名 + メール連携）|
| 機密情報 | Firebase Web API Key のみ許容。サーバーキー禁止 |

## 7. CI/CD 設計

### GitHub Actions ワークフロー

```
main push
  ├── deploy.yml
  │   ├── flutter analyze
  │   ├── flutter test --coverage
  │   ├── Stamp deploy timestamp (sed → app_version.dart)
  │   ├── flutter build web --release
  │   └── Deploy to GitHub Pages
  │
  └── test.yml (PR only)
      ├── flutter analyze
      └── flutter test --coverage
```

### Claude Code Hooks（品質自動チェック）

| Hook | タイミング | チェック内容 |
|---|---|---|
| PostToolUse (Write/Edit) | ファイル編集後 | dart format 自動実行 |
| Stop (command) | セッション終了時 | flutter analyze + flutter test + ハードコード検出 |
| Stop (prompt) | セッション終了時 | 横展開/セキュリティ/パフォーマンス/テスト整合性のAIチェック |

## 8. テスト設計

### テスト構成

```
test/
├── models/          # モデルの単体テスト
├── database/        # DAO の単体テスト
├── services/        # サービスの単体テスト
├── providers/       # Provider の統合テスト
├── pages/           # ページの Widget テスト
├── dialogs/         # ダイアログの Widget テスト
├── widgets/         # カスタムウィジェットのテスト
├── integration/     # アプリフローの統合テスト
├── data/            # テンプレートデータのテスト
├── helpers/         # テストユーティリティ
└── widget_test.dart # スモークテスト
```

### テストルール

- テスト環境では `disableInboxCheckForTest()` を呼ぶ（非同期ハング防止）
- Drift の `isNull`/`isNotNull` は flutter_test と競合するため `hide`
- GoRouter はモジュールレベルシングルトン。テストではドロワー経由ナビゲーション使用
- ラベル変更時はテストの旧文言を `grep` で検索し全て更新
