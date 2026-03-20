# ユメログ リリース運用フロー

## 概要

新機能のリリースからユーザーへの通知までを、`release_config.json` の更新とプッシュだけで完結させる自動化フローです。

---

## リリース手順

### 1. `release_config.json` を更新

リポジトリルートの `release_config.json` を編集します。

```json
{
  "version": "1.2.0",
  "notes": [
    "書籍画面を本棚UIにリニューアル",
    "夢にカテゴリ機能を追加",
    "目標の達成率を視覚化"
  ]
}
```

| フィールド | 説明 |
|-----------|------|
| `version` | バージョン番号（前回と異なる値にする） |
| `notes` | ユーザーに表示するリリースノート（配列） |

### 2. コミット＆プッシュ

```bash
git add release_config.json
git commit -m "v1.2.0 リリース"
git push
```

### 3. 自動実行される処理

プッシュ後、GitHub Actions（`deploy.yml`）が以下を順番に実行します:

```
①  flutter analyze（静的解析）
②  flutter test --coverage（テスト実行）
③  flutter build web（Webビルド）
④  GitHub Pages にデプロイ
⑤  Gist の release セクションを自動更新
```

### 4. ユーザーへの通知

ユーザーがアプリにアクセスすると:
- Gist から最新の `release.version` を取得
- 前回確認したバージョンと比較
- 新しいバージョンであれば「新機能のお知らせ」ダイアログを自動表示
- 確認後は同じバージョンでは再表示されない

---

## 仕組みの詳細

### ファイル構成

| ファイル | 役割 |
|---------|------|
| `release_config.json` | リリース情報の定義（開発者が編集） |
| `.github/workflows/deploy.yml` | デプロイ＋Gist自動更新 |
| `lib/services/remote_config_service.dart` | Gistからリリースノートを取得 |
| `lib/dialogs/release_notes_dialog.dart` | リリースノートダイアログUI |
| `lib/app.dart` | アプリ起動時にリリースノートを確認・表示 |

### データフロー

```
release_config.json
    ↓ (GitHub Actions)
Gist JSON の release セクション
    ↓ (アプリ起動時に取得)
RemoteConfigService.fetchReleaseNotes()
    ↓ (バージョン比較)
SharedPreferences の release_notes_seen_version
    ↓ (未確認の場合)
showReleaseNotesDialog() でユーザーに表示
```

### Gist JSON の構造

```json
{
    "users": {
        "dev-reset": { ... },
        "dev-continue": { ... }
    },
    "invites": {
        "invitationCode": { ... }
    },
    "release": {
        "version": "1.2.0",
        "notes": [
            "書籍画面を本棚UIにリニューアル",
            "夢にカテゴリ機能を追加"
        ]
    }
}
```

`release` セクションは GitHub Actions が自動で更新するため、Gistを手動で編集する必要はありません。

---

## GitHub Actions の設定

### 必要なSecret

| Secret名 | 説明 |
|----------|------|
| `GIST_TOKEN` | GitHub Personal Access Token（Gist Read/Write権限） |

### トークンの再発行が必要な場合

1. https://github.com/settings/tokens?type=beta にアクセス
2. 「Generate new token」→ Fine-grained token
3. Permissions → Account permissions → Gists: Read and write
4. リポジトリの Settings → Secrets → `GIST_TOKEN` を更新

---

## バージョニングルール

| 変更内容 | バージョン例 |
|---------|------------|
| バグ修正のみ | 1.1.1 → 1.1.2 |
| 機能追加・改善 | 1.1.0 → 1.2.0 |
| 大規模リニューアル | 1.2.0 → 2.0.0 |

---

## 注意事項

- `version` を変更しないとユーザーにリリースノートが表示されません
- `notes` が空配列の場合もダイアログは表示されません
- Gist更新はデプロイ成功後にのみ実行されます（テスト失敗時は更新されません）
- `release_config.json` を変更せずにプッシュした場合、Gistは同じ内容で上書きされるだけなので問題ありません

---

> **最終更新日**: 2026年3月20日
