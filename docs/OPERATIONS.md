# ユメログ 運用手順書

## 目次

1. [日常的な改修フロー](#1-日常的な改修フロー)
2. [バージョンアップ・リリース手順](#2-バージョンアップリリース手順)
3. [ラベル・メッセージの修正](#3-ラベルメッセージの修正)
4. [ユーザーへの通知配信](#4-ユーザーへの通知配信)
5. [管理ファイル一覧](#5-管理ファイル一覧)
6. [Claude Code 設定（Skills / Hooks / Agents）](#6-claude-code-設定skills--hooks--agents)
7. [GitHub Actions（自動処理）](#7-github-actions自動処理)
8. [トラブルシューティング](#8-トラブルシューティング)

---

## 1. 日常的な改修フロー

### 手順

```
1. ソースコード修正 + 対応するテストコード追加・修正
2. ローカル確認: flutter analyze（エラー0件）
3. ローカル確認: run_windows.bat で動作確認
4. main ブランチにコミット & プッシュ
5. GitHub Actions が自動で テスト → ビルド → GitHub Pages デプロイ
6. ブラウザで https://teppei19980914.github.io/GrowthEngine/ を動作確認
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

GitHub Actions のデプロイ失敗を防ぐため、コミット前にローカルで以下を実行する:

```bash
# Step 1: 静的解析（GitHub Actions の flutter analyze と同等）
flutter analyze

# Step 2: 全テスト実行（GitHub Actions の flutter test と同等）
flutter test

# Step 3: Web ビルド確認（GitHub Actions の flutter build web と同等）
flutter build web --release --base-href "/GrowthEngine/"
```

**全て成功した場合のみコミット & プッシュする。**

#### よくあるデプロイ失敗の原因と事前対策

| 失敗原因 | 事前チェック方法 |
|---|---|
| `flutter analyze` エラー | `flutter analyze` をローカルで実行 |
| テスト失敗（旧ラベル文字列の残留） | `grep` で旧文言を `test/` 配下から検索 |
| テスト失敗（制限値変更の未反映） | `test/services/trial_limit_service_test.dart` を確認 |
| アセット参照エラー | `pubspec.yaml` の `assets:` セクションを確認 |
| import 未使用・重複定義 | `flutter analyze` で検出可能 |

#### デプロイ失敗時の対応

```bash
# 1. 失敗ログを取得
gh run list --limit 1
gh run view <RUN_ID> --log-failed

# 2. ローカルで再現・修正
flutter analyze    # エラーがあれば修正
flutter test       # 失敗テストを修正

# 3. 再コミット & プッシュ
```

または `/check-deploy` スキルを使用して Claude Code に調査・修正を依頼。

---

## 2. バージョンアップ・リリース手順

新バージョンをリリースする場合、以下の手順で進める。

### Step 1: バージョン番号とリリース履歴の更新

以下の **2ファイル** を同時に更新する。

**pubspec.yaml** — ビルドバージョン
```yaml
version: 1.1.0+2   # ← バージョンとビルド番号を更新
```

**lib/app_version.dart** — 表示バージョン + リリース履歴
```dart
const appVersion = '1.1.0';  // ← pubspec.yaml と一致させる

const releaseHistory = <ReleaseEntry>[
  // ↓ 先頭に新バージョンを追加（過去分はそのまま残す）
  ReleaseEntry(
    version: '1.1.0',
    date: '2026-04-01',
    notes: [
      '受信ボックス機能を追加',
      'スケジュール画面の操作性を改善',
      '書籍管理の表示を最適化',
    ],
  ),
  // ↓ 過去のリリース履歴（削除しない）
  ReleaseEntry(
    version: '1.0.0',
    date: '2026-03-29',
    notes: [
      '初回リリース',
    ],
  ),
];
```

> **重要**: `releaseHistory` は新しい順に蓄積する。過去のエントリは削除しない。
> 将来リリース履歴画面を表示する際のデータソースになる。

### Step 2: 受信ボックスへの通知配信（任意）

リリースをユーザーの受信ボックスにも通知したい場合:

**assets/announcements.json**
```json
[
  {
    "dedup_key": "release:1.1.0",
    "date": "2026-04-01",
    "title": "v1.1.0 をリリースしました",
    "message": "受信ボックス機能やスケジュール改善など、多くの新機能を追加しました。"
  }
]
```

### Step 3: コミット & プッシュ

```bash
git add pubspec.yaml lib/app_version.dart assets/announcements.json
git commit -m "v1.1.0 リリース"
git push origin main
```

### 動作の流れ

```
ユーザーがアプリにアクセス
  │
  ├─ app_version.dart の appVersion を前回表示バージョンと比較
  │   └─ 異なる場合 → リリースノートポップアップを表示（releaseHistory の先頭）
  │
  └─ announcements.json を受信ボックスに同期
      └─ エントリがあれば受信ボックスに通知表示
```

### リリース履歴の活用

`releaseHistory` には全バージョンの変更履歴が蓄積される。

| 参照元 | 使用データ |
|---|---|
| リリースノートポップアップ | `releaseHistory` の先頭（最新版のみ） |
| 設定画面のバージョン表示 | `appVersion` |
| リリース履歴画面（将来） | `releaseHistory` の全件 |

---

## 3. ラベル・メッセージの修正

### 修正対象ファイル

**lib/l10n/app_labels.dart**

アプリ内のすべてのラベル名・ボタン名・メッセージは、このファイルで一元管理している。

### 修正例

ボタン名を変更する場合:
```dart
// Before
static const btnCancel = 'キャンセル';

// After
static const btnCancel = 'やめる';
```

この1箇所の変更で、アプリ内の全ての「キャンセル」ボタンが自動的に更新される。

### 主なカテゴリ

| カテゴリ | 変数プレフィックス | 例 |
|---|---|---|
| ページ名 | `page` | `pageHome`, `pageGoals` |
| ボタン | `btn` | `btnCancel`, `btnDelete` |
| ツールチップ | `tooltip` | `tooltipMenu`, `tooltipHelp` |
| 夢関連 | `dream` | `dreamTitle`, `dreamDialogAdd` |
| 目標関連 | `goal` | `goalWhat`, `goalDialogEdit` |
| タスク関連 | `task` | `taskName`, `taskAdd` |
| 書籍関連 | `book` | `bookTitle`, `bookAddButton` |
| 統計関連 | `stats` | `statsSummary`, `statsNoData` |
| 受信ボックス | `inbox` | `inboxTitle`, `inboxEmpty` |
| エラー | `error` | `errorGeneral`, `errorWithDetail()` |
| バリデーション | `valid` | `validRequired`, `validEmail` |

### 注意事項

- テストコード内でラベル文字列を直接検索している場合はテストも修正する
- `static const` のため、変数名の変更はコンパイルエラーで検出可能
- 同じ画面を指すラベルは1つの変数で管理する（例: ナビもタイトルも `pageGoals`）

---

## 4. ユーザーへの通知配信

### 管理ファイル

**assets/announcements.json**

このファイルの内容がアプリ起動時に受信ボックスのDBと完全同期される。

### 通知の追加

```json
[
  {
    "dedup_key": "announce:2026-04-15:maintenance",
    "date": "2026-04-15",
    "title": "メンテナンスのお知らせ",
    "message": "4/20 10:00〜12:00 にサーバーメンテナンスを実施します。"
  }
]
```

### 通知の削除

JSONからエントリを削除するだけで、次回アプリ起動時にユーザーの受信ボックスからも消える。

```json
[]
```

### 通知の修正

JSONのエントリを直接編集する。`dedup_key` が同じなら同じ通知として扱われる。

### フィールド仕様

| フィールド | 必須 | 形式 | 説明 |
|---|---|---|---|
| `dedup_key` | 必須 | 文字列 | 一意のキー（例: `announce:2026-04-15:maintenance`） |
| `date` | 任意 | `yyyy-MM-dd` | 通知の表示日付。未指定時は現在日時 |
| `title` | 必須 | 文字列 | 受信ボックスの件名 |
| `message` | 必須 | 文字列 | 受信ボックスの本文 |

### 受信ボックスの通知種別

| 種別 | データソース | 動作 |
|---|---|---|
| 開発者通知 | `announcements.json` | JSONとDBを完全同期。JSONの編集がそのまま反映 |
| リマインド | ユーザーのタスク/目標 | アプリ起動時に期限を自動チェック。ユーザーごとに異なる |
| 実績 | ユーザーの活動記録 | マイルストーン達成時に自動生成。ユーザーごとに異なる |

### 操作一覧

| やりたいこと | 操作 |
|---|---|
| お知らせを配信 | `announcements.json` にエントリ追加 → コミット & プッシュ |
| お知らせを削除 | `announcements.json` からエントリ削除 → コミット & プッシュ |
| お知らせを修正 | `announcements.json` の該当エントリを編集 → コミット & プッシュ |
| リリース情報を配信 | `app_version.dart` 更新 + `announcements.json` にエントリ追加 |

---

## 5. 管理ファイル一覧

| ファイル | 役割 | 更新タイミング |
|---|---|---|
| `pubspec.yaml` | アプリのバージョン番号（ビルド用） | バージョンアップ時 |
| `lib/app_version.dart` | バージョン番号 + リリース履歴（蓄積） | バージョンアップ時 |
| `lib/l10n/app_labels.dart` | 全ラベル・メッセージ | テキスト修正時 |
| `assets/announcements.json` | 開発者通知（受信ボックス） | お知らせ配信時 |
| `CLAUDE.md` | Claude Code 運用ガイド・チェックリスト | 開発ルール変更時 |
| `.claude/settings.json` | Claude Code 許可設定・Hooks | 許可追加・Hook変更時 |
| `.claude/skills/*.md` | Claude Code スキル（4ファイル） | 作業手順変更時 |
| `.claude/agents/*.md` | Claude Code エージェント（3ファイル） | チェック項目変更時 |
| [docs/REQUIREMENTS.md](REQUIREMENTS.md) | 要件定義書 | 機能追加・要件変更時 |
| [docs/SPECIFICATION.md](SPECIFICATION.md) | 仕様書（テーマ・コンセプト含む） | 画面仕様・制限仕様変更時 |
| [docs/DESIGN.md](DESIGN.md) | 設計書 | アーキテクチャ・データモデル変更時 |
| [docs/OPERATIONS.md](OPERATIONS.md) | 本手順書 | 運用手順変更時 |
| [docs/README.md](README.md) | プロジェクト概要 | 機能一覧・構成変更時 |

### ファイル間の関係

```
pubspec.yaml          ← ビルドバージョン（正）
    ↓ 一致させる
app_version.dart      ← 表示バージョン + リリース履歴（蓄積）
    ├─ 最新エントリ → リリースノートポップアップ
    └─ 全エントリ   → リリース履歴画面（将来）

announcements.json    ← 開発者通知（JSONとDBを完全同期）
    ↓
受信ボックス

app_labels.dart       ← 全ラベル・メッセージ
    ↓ 参照
全画面のテキスト
```

### バージョンアップ時のチェックリスト

- [ ] `pubspec.yaml` の `version:` を更新
- [ ] `lib/app_version.dart` の `appVersion` を一致させる
- [ ] `lib/app_version.dart` の `releaseHistory` 先頭にエントリ追加
- [ ] 必要に応じて `assets/announcements.json` に通知追加
- [ ] `flutter analyze` でエラー0件を確認
- [ ] コミット & プッシュ

---

## 6. Claude Code 設定（Skills / Hooks / Agents）

Claude Code の自動化設定は以下のファイルで管理している。

### 設定ファイル一覧

| ファイル | 役割 | 編集タイミング |
|---|---|---|
| [CLAUDE.md](../CLAUDE.md) | プロジェクトルール（毎セッション自動読み込み） | 開発ルール変更時 |
| [.claude/settings.json](../.claude/settings.json) | 許可設定・Hooks定義 | 許可追加・Hook変更時 |
| [.claude/skills/fix-issue.md](../.claude/skills/fix-issue.md) | 問題修正スキル（`/fix-issue`） | 修正手順変更時 |
| [.claude/skills/release.md](../.claude/skills/release.md) | リリーススキル（`/release`） | リリース手順変更時 |
| [.claude/skills/check-deploy.md](../.claude/skills/check-deploy.md) | デプロイ確認スキル（`/check-deploy`） | 確認手順変更時 |
| [.claude/skills/update-labels.md](../.claude/skills/update-labels.md) | ラベル更新スキル（`/update-labels`） | ラベル運用変更時 |
| [.claude/agents/security-reviewer.md](../.claude/agents/security-reviewer.md) | セキュリティレビューAgent | チェック項目変更時 |
| [.claude/agents/performance-reviewer.md](../.claude/agents/performance-reviewer.md) | パフォーマンスレビューAgent | チェック項目変更時 |
| [.claude/agents/label-checker.md](../.claude/agents/label-checker.md) | ラベル漏れチェックAgent | 検出ルール変更時 |

### Skills（スキル）の使い方

セッション中にコマンドで呼び出す。呼び出し時のみトークンを消費する。

| コマンド | 用途 |
|---|---|
| `/fix-issue` | SonarCloud/UIテストレポートから問題を修正 |
| `/release` | バージョンアップ・リリース作業を実行 |
| `/check-deploy` | GitHub Actionsのデプロイ失敗を調査・修正 |
| `/update-labels` | ラベル・メッセージの変更と横展開 |

### Hooks（自動処理）

`.claude/settings.json` の `hooks` セクションで定義。人手を介さず自動実行される。

| Hook | トリガー | 動作 |
|---|---|---|
| **PostToolUse (Write/Edit)** | ファイル編集後 | `dart format --fix` を自動実行 |
| **Stop (command)** | セッション終了時 | `flutter analyze` → `flutter test` → ハードコード日本語検出 を自動実行 |
| **Stop (prompt)** | セッション終了時 | AI が横展開・セキュリティ・パフォーマンス・テスト整合性を最終チェック |

**Stop Hook により、以下のチェックがセッション終了時に必ず実行される:**

1. `flutter analyze` — 静的解析エラー0件の確認
2. `flutter test` — 全テスト合格の確認
3. ハードコード日本語検出 — `AppLabels` 未適用の文字列がないか検出
4. 横展開チェック — 修正パターンの他ファイルへの残留確認（AI判定）
5. セキュリティチェック — サニタイズ漏れ、生SQL、機密情報（AI判定）
6. パフォーマンスチェック — N+1クエリ、Paint生成、Provider設計（AI判定）
7. テスト整合性 — ラベル変更時の旧文言残留確認（AI判定）

### Agents（並行レビュー）

指示時に独立したサブプロセスとして起動する。

| 指示例 | 起動するAgent |
|---|---|
| 「セキュリティチェックして」 | security-reviewer |
| 「パフォーマンスチェックして」 | performance-reviewer |
| 「ハードコードの日本語が残っていないかチェック」 | label-checker |

### 設定の変更ルール

- **CLAUDE.md**: 150行以内を維持。詳細手順は Skills に移行
- **Skills**: 繰り返し使う作業手順を配置。CLAUDE.md と重複する詳細は Skills 側に集約
- **Hooks**: 手動で繰り返している作業があれば Hook 化を検討
- **Agents**: 独立して並行実行できるレビュー作業を配置

---

## 7. GitHub Actions（自動処理）

### deploy.yml（main push 時）

```
flutter analyze → flutter test --coverage → flutter build web → GitHub Pages デプロイ
```

- テスト失敗時はデプロイされない
- カバレッジレポートは Summary タブに出力
- デプロイ先: https://teppei19980914.github.io/GrowthEngine/

### test.yml（PR 時）

```
flutter analyze → flutter test --coverage
```

- PR のマージ可否判定に使用
- デプロイは行わない

---

## 8. トラブルシューティング

### デプロイ後にリリースノートポップアップが表示されない

- `lib/app_version.dart` の `appVersion` が前回と同じ値になっていないか確認
- `pubspec.yaml` と `app_version.dart` のバージョンが一致しているか確認
- `releaseHistory` の先頭エントリが最新バージョンか確認

### 受信ボックスの通知が消えない

- `announcements.json` からエントリを削除してコミット & プッシュしたか確認
- ユーザーがアプリを再アクセス（ページリロード）したか確認
- リマインド・実績通知は `announcements.json` では管理されない（自動生成）

### ラベル変更がテストに影響する

- `test/` 配下で変更前のラベル文字列を `grep` で検索し、テストも修正する
- `flutter analyze` でコンパイルエラーは検出できるが、文字列一致テストは手動確認が必要

### ローカルで Windows アプリが起動しない

```bash
# Flutter の状態確認
flutter doctor

# 依存関係の再取得
flutter pub get

# Windows ビルドの確認
flutter run -d windows
```

### GitHub Actions のデプロイが失敗する

- GitHub リポジトリの Settings → Pages → Source が「GitHub Actions」になっているか確認
- Actions タブでエラーログを確認
- `flutter analyze` または `flutter test` の失敗が原因の場合はローカルで再現・修正
