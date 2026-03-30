# ユメログ（YumeLog）技術スタック ナレッジベース

> 個人開発プロジェクト「ユメログ」で採用した技術スタック・ツール・サービスの知見を整理し、
> 今後の技術選定やチーム共有に活用するためのドキュメントです。

---

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [言語・フレームワーク](#2-言語フレームワーク)
3. [主要ライブラリ](#3-主要ライブラリ)
4. [CI/CD パイプライン](#4-cicd-パイプライン)
5. [静的解析・品質管理](#5-静的解析品質管理)
6. [テスト戦略](#6-テスト戦略)
7. [ホスティング・デプロイ](#7-ホスティングデプロイ)
8. [外部サービス連携](#8-外部サービス連携)
9. [決済サービス](#9-決済サービス)
10. [アーキテクチャ設計](#10-アーキテクチャ設計)
11. [技術選定の比較表](#11-技術選定の比較表)
12. [開発で得た知見・教訓](#12-開発で得た知見教訓)

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| **アプリ名** | ユメログ（YumeLog） |
| **種別** | 目標管理・タスク管理 Web アプリケーション |
| **対象プラットフォーム** | Web（GitHub Pages）、モバイルブラウザ対応 |
| **開発期間** | 2026年3月〜 |
| **開発体制** | 個人開発 + Claude Code（AI ペアプログラミング） |
| **リポジトリ** | GitHub Private リポジトリ |
| **公開URL** | https://teppei19980914.github.io/GrowthEngine/ |

---

## 2. 言語・フレームワーク

### Flutter（Dart）

| 項目 | 詳細 |
|------|------|
| **Dart SDK** | ^3.11.1 |
| **Flutter チャネル** | stable |
| **ビルドターゲット** | Web（`flutter build web --release`） |

#### Flutter を選定した理由

- **マルチプラットフォーム**: 単一コードベースで Web / Android / iOS / Windows に対応可能
- **宣言的 UI**: ウィジェットベースの UI 構築で再利用性が高い
- **豊富なエコシステム**: pub.dev に多数のパッケージが公開されている
- **ホットリロード**: 開発効率が高い

#### 比較検討した代替技術

| 技術 | メリット | デメリット | 不採用理由 |
|------|----------|------------|------------|
| **React + Next.js** | Web に最適化、SSR 対応 | モバイルは別途 React Native が必要 | マルチプラットフォーム対応が分断される |
| **React Native** | モバイルに強い | Web 対応が限定的 | Web ファーストの要件に合わない |
| **Kotlin Multiplatform** | ネイティブパフォーマンス | UI 共有が限定的、学習コスト高 | 個人開発には重い |
| **PWA（HTML/JS）** | 軽量、学習コスト低 | 複雑な UI 構築が困難 | ガントチャート等のリッチ UI に不向き |

---

## 3. 主要ライブラリ

### 状態管理: flutter_riverpod ^2.5.0

| 項目 | 詳細 |
|------|------|
| **役割** | アプリ全体の状態管理・依存性注入 |
| **特徴** | コンパイル時安全性、Provider の自動破棄、テスト容易性 |
| **採用理由** | グローバルステートの管理が直感的で、テスト時のオーバーライドが容易 |

#### 状態管理ライブラリ比較

| ライブラリ | 学習コスト | テスト容易性 | スケーラビリティ | 選定 |
|------------|-----------|------------|----------------|------|
| **Riverpod** | 中 | ◎ | ◎ | **採用** |
| Provider | 低 | ○ | △ | Riverpod の前身、機能が限定的 |
| BLoC | 高 | ◎ | ◎ | ボイラープレートが多い |
| GetX | 低 | △ | △ | テスト性・保守性に懸念 |
| MobX | 中 | ○ | ○ | Dart 向けの情報が少ない |

### データベース: Drift ^2.18.0（SQLite ORM）

| 項目 | 詳細 |
|------|------|
| **役割** | ローカル SQLite データベースの ORM |
| **特徴** | 型安全なクエリ、マイグレーション対応、Web WASM 対応 |
| **Web 対応** | `drift_worker.js` を使用した Web WASM SQLite |
| **採用理由** | 複雑なリレーション（夢→目標→タスク）を型安全に扱える |

#### データベースライブラリ比較

| ライブラリ | 型安全性 | Web 対応 | リレーション | 選定 |
|------------|---------|---------|-------------|------|
| **Drift** | ◎ | ◎（WASM） | ◎ | **採用** |
| sqflite | △ | × | △ | Web 非対応 |
| Hive | △ | ○ | × | NoSQL のみ |
| Isar | ○ | △ | ○ | Web 対応が限定的 |
| ObjectBox | ○ | × | ○ | Web 非対応 |

### ルーティング: go_router ^14.0.0

| 項目 | 詳細 |
|------|------|
| **役割** | URL ベースのルーティング |
| **特徴** | 宣言的ルーティング、ディープリンク対応 |
| **注意点** | シングルトンのため、テスト間で状態がリークする場合がある |

### グラフ描画: fl_chart ^0.68.0

| 項目 | 詳細 |
|------|------|
| **役割** | 統計ページのグラフ描画（棒グラフ、折れ線グラフ等） |
| **採用理由** | Flutter ネイティブで軽量、カスタマイズ性が高い |

### その他ライブラリ一覧

| ライブラリ | バージョン | 用途 |
|-----------|-----------|------|
| shared_preferences | ^2.2.0 | 設定値の永続化（テーマ、チュートリアル状態等） |
| http | ^1.6.0 | HTTP 通信（フィードバック送信、Stripe 連携） |
| url_launcher | ^6.3.2 | 外部 URL の起動（Stripe Checkout 画面遷移） |
| uuid | ^4.4.0 | 一意な ID 生成 |
| intl | ^0.19.0 | 日付フォーマット・国際化 |
| file_picker | ^8.0.0 | ファイル選択（データインポート） |
| share_plus | ^9.0.0 | データ共有（エクスポート） |
| excel | ^4.0.6 | Excel 形式でのデータ出力 |
| archive | ^3.6.0 | ファイル圧縮・解凍 |
| path_provider | ^2.1.0 | プラットフォーム固有のディレクトリパス取得 |
| cupertino_icons | ^1.0.8 | iOS スタイルアイコン |

---

## 4. CI/CD パイプライン

### GitHub Actions

全ワークフローは `.github/workflows/` に配置。

| ワークフロー | トリガー | 主な処理 | 成果物 |
|-------------|---------|---------|--------|
| **deploy.yml** | main push | テスト → ビルド → GitHub Pages デプロイ | Web アプリ公開 |
| **test.yml** | PR 作成時 | テスト（カバレッジ付き） | カバレッジレポート |
| **sonarcloud.yml** | main push | テスト → SonarCloud 解析 → レポート保存 | `sonarcloud-reports/latest-report.txt` |
| **integration_test.yml** | main push | UI インテグレーションテスト → レポート保存 | `integration_test_reports/latest-report.txt` |

#### deploy.yml の処理フロー

```
Checkout → Flutter Setup → pub get → flutter analyze → flutter test --coverage
  → Coverage Report → flutter build web → Upload to GitHub Pages → Deploy
```

#### GitHub Actions 比較

| CI/CD サービス | 無料枠 | GitHub 連携 | 設定の容易さ | 選定 |
|---------------|--------|------------|------------|------|
| **GitHub Actions** | 2,000分/月 | ◎（ネイティブ） | ◎ | **採用** |
| CircleCI | 6,000分/月 | ○ | ○ | GitHub Actions で十分 |
| GitLab CI | 400分/月 | △ | ○ | GitHub リポジトリとの相性 |
| Codemagic | 500分/月 | ○ | ◎（Flutter 特化） | 無料枠が少ない |
| Bitrise | 90分/月 | ○ | ○ | モバイル特化で Web に弱い |

---

## 5. 静的解析・品質管理

### SonarCloud

| 項目 | 詳細 |
|------|------|
| **役割** | コード品質・セキュリティの継続的な監視 |
| **プロジェクトキー** | `teppei19980914_GrowthEngine` |
| **対象** | `lib/` 配下の Dart コード |
| **除外** | 生成コード（`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`） |
| **カバレッジ** | `flutter test --coverage` の `lcov.info` を連携 |
| **コスト** | 無料（パブリックリポジトリ）/ 無料枠あり（プライベート） |

#### SonarCloud が検出する問題

| カテゴリ | 説明 | 重要度 |
|---------|------|--------|
| **Bugs** | ランタイムエラーの原因となるコード | BLOCKER〜MINOR |
| **Vulnerabilities** | セキュリティ脆弱性 | BLOCKER〜MINOR |
| **Security Hotspots** | セキュリティレビューが必要な箇所 | — |
| **Code Smells** | 保守性を低下させるコード | MAJOR〜INFO |
| **Coverage** | テストカバレッジ率 | — |
| **Duplications** | コードの重複率 | — |

#### レポート自動保存

- `sonarcloud-reports/latest-report.txt` に最新レポートを自動コミット
- 日付付きバックアップ（`report-YYYYMMDD.txt`）も同時保存
- Claude Code がレポートを読み取り、指摘事項を自動修正するワークフローに組み込み

#### 静的解析ツール比較

| ツール | 言語対応 | Dart 対応 | CI 連携 | コスト | 選定 |
|--------|---------|----------|--------|--------|------|
| **SonarCloud** | 30+ 言語 | ◎ | ◎ | 無料枠あり | **採用** |
| Dart Analyzer | Dart のみ | ◎ | ◎ | 無料 | **併用**（`flutter analyze`） |
| CodeClimate | 15+ 言語 | △ | ○ | 無料枠あり | Dart 対応が弱い |
| Codacy | 40+ 言語 | △ | ○ | 無料枠あり | Dart 対応が弱い |
| Snyk | セキュリティ特化 | △ | ○ | 無料枠あり | 依存関係の脆弱性のみ |

---

## 6. テスト戦略

### テストピラミッド

```
          ┌─────────────┐
          │ Integration  │  UIインテグレーションテスト（GitHub Actions / Linux）
          │   Tests      │  integration_test/app_test.dart
          ├─────────────┤
          │  Widget      │  ウィジェット単体テスト
          │  Tests       │  test/pages/, test/widgets/, test/dialogs/
          ├─────────────┤
          │  Unit        │  サービス・モデルの単体テスト
          │  Tests       │  test/services/, test/models/, test/providers/
          └─────────────┘
```

### テストツール

| ツール | 用途 | 備考 |
|--------|------|------|
| **flutter_test** | ウィジェット・単体テスト | Flutter SDK 標準 |
| **integration_test** | UI 統合テスト | Flutter SDK 標準、Linux ヘッドレス実行 |
| **mocktail** | モック生成 | コード生成不要の軽量モックライブラリ |
| **xvfb** | ヘッドレス UI テスト | CI 環境で Linux デスクトップテストを実行 |

### テストのルール

- 全てのソースコード（生成コード・UI の catch 句等を除く）がテスト対象
- テストファイルは `test/` 配下にソースと対応する構造で配置
- テストコードの追加・修正を伴わないソースコード変更はコミットしない
- Drift の `isNull` / `isNotNull` は flutter_test と競合するため `hide` する
- DateTime 比較は SQLite のミリ秒精度に注意し秒単位で切り捨てる

### モックライブラリ比較

| ライブラリ | コード生成 | 学習コスト | 柔軟性 | 選定 |
|-----------|-----------|-----------|--------|------|
| **mocktail** | 不要 | 低 | ○ | **採用** |
| mockito | 必要（build_runner） | 中 | ◎ | コード生成が面倒 |
| fake | 不要 | 低 | △ | 機能が限定的 |

---

## 7. ホスティング・デプロイ

### GitHub Pages

| 項目 | 詳細 |
|------|------|
| **役割** | Web アプリの静的ホスティング |
| **URL** | `https://teppei19980914.github.io/GrowthEngine/` |
| **ビルドコマンド** | `flutter build web --release --base-href "/GrowthEngine/"` |
| **デプロイ方法** | GitHub Actions から自動デプロイ |
| **コスト** | 完全無料 |

#### ホスティングサービス比較

| サービス | コスト | SSL | カスタムドメイン | サーバーサイド | 選定 |
|---------|--------|-----|----------------|-------------|------|
| **GitHub Pages** | 無料 | ◎ | ○ | × | **採用** |
| Vercel | 無料枠あり | ◎ | ○ | ○（Edge Functions） | 静的サイトには過剰 |
| Netlify | 無料枠あり | ◎ | ○ | ○（Functions） | 静的サイトには過剰 |
| Firebase Hosting | 無料枠あり | ◎ | ○ | ○（Cloud Functions） | 認証不要なので過剰 |
| Cloudflare Pages | 無料 | ◎ | ○ | ○（Workers） | 有力な代替候補 |
| AWS S3 + CloudFront | 従量課金 | ◎ | ○ | × | コスト管理が煩雑 |

---

## 8. 外部サービス連携

### GitHub Gist（リモート設定）

| 項目 | 詳細 |
|------|------|
| **役割** | ユーザー設定・招待コード・機能フラグのリモート管理 |
| **Gist ID** | `d68bbdb601a9d0e409244c141f25e3fc`（Secret Gist） |
| **データ形式** | JSON |
| **アクセス方法** | HTTPS GET（認証不要、Secret Gist は URL を知っている人のみアクセス可） |
| **コスト** | 完全無料 |

#### Gist JSON 構造

```json
{
  "users": {
    "dev-reset": { "name": "開発者", "unlimited": true, "resetOnAccess": true },
    "user-key": { "name": "ユーザー名", "unlimited": false }
  },
  "invites": {
    "INVITE-CODE": { "name": "招待ユーザー名", "durationDays": 60 }
  }
}
```

#### リモート設定サービス比較

| サービス | コスト | リアルタイム更新 | 管理 UI | 選定 |
|---------|--------|----------------|--------|------|
| **GitHub Gist** | 無料 | △（ポーリング） | △（手動編集） | **採用** |
| Firebase Remote Config | 無料枠あり | ◎ | ◎ | Firebase 依存が増える |
| LaunchDarkly | 有料 | ◎ | ◎ | 個人開発にはコスト過剰 |
| Unleash | OSS 無料 | ◎ | ◎ | セルフホスト必要 |

### Google Apps Script（バックエンド代替）

| 項目 | 詳細 |
|------|------|
| **役割** | フィードバック受信・Stripe Checkout Session 作成 |
| **実行環境** | Google Cloud（サーバーレス） |
| **デプロイ** | ウェブアプリとしてデプロイ（URL エンドポイント） |
| **データ保存先** | Google スプレッドシート |
| **通知** | Gmail（MailApp.sendEmail） |
| **コスト** | 完全無料 |

#### 用途別エンドポイント

| エンドポイント | 用途 | 処理内容 |
|--------------|------|---------|
| フィードバック用 GAS | フィードバック・お問い合わせ受信 | スプレッドシート記録 + メール通知 |
| Stripe 用 GAS | Checkout Session 作成 | Stripe API 呼び出し + URL 返却 |

#### バックエンド代替サービス比較

| サービス | コスト | 設定の容易さ | スケーラビリティ | 選定 |
|---------|--------|------------|----------------|------|
| **Google Apps Script** | 無料 | ◎ | △ | **採用** |
| Cloudflare Workers | 無料枠あり | ○ | ◎ | 有力な代替候補 |
| AWS Lambda | 従量課金 | △ | ◎ | 設定が煩雑 |
| Vercel Edge Functions | 無料枠あり | ○ | ◎ | フロントと分離したい場合に有力 |
| Supabase Edge Functions | 無料枠あり | ○ | ○ | DB 連携が必要な場合に有力 |

---

## 9. 決済サービス

### Stripe

| 項目 | 詳細 |
|------|------|
| **役割** | サブスクリプション月額決済（¥480/月） |
| **連携方式** | Stripe Checkout（ホスト型決済画面） |
| **フロー** | アプリ → GAS → Stripe Checkout Session → Stripe 決済画面 → コールバック |
| **月額費用** | 0 円（決済発生時のみ手数料） |
| **手数料** | 3.6% + ¥40/件 |
| **テスト環境** | テストモードで本番と同じフローを検証可能 |

#### 決済フロー

```
[ユーザー] → [アプリ: 申し込むボタン]
    → [Google Apps Script: Checkout Session 作成]
    → [Stripe: ホスト型決済画面（カード入力）]
    → [決済完了: アプリにリダイレクト ?subscription=success]
    → [アプリ: SharedPreferences に購読状態を保存]
```

#### Stripe を選定した理由

- **PCI DSS 準拠不要**: カード情報は Stripe が管理（Checkout 方式）
- **初期費用・月額費用 0 円**: 完全従量課金
- **日本語対応**: ダッシュボード・決済画面ともに日本語
- **テストモード**: 本番環境と同一フローで検証可能
- **サブスク管理自動化**: 月次課金・解約・再開を Stripe 側で管理

#### 決済サービス比較

| サービス | 手数料 | 初期/月額 | サブスク対応 | 日本語 | 選定 |
|---------|--------|---------|------------|--------|------|
| **Stripe** | 3.6% + ¥40 | 無料 | ◎ | ◎ | **採用** |
| PayPal | 3.6% + ¥40 | 無料 | △ | ○ | サブスク管理が弱い |
| Square | 3.25% | 無料 | △ | ○ | 対面決済向け |
| Paddle | 5% + 50¢ | 無料 | ◎ | △ | 手数料が高い |
| LemonSqueezy | 5% + 50¢ | 無料 | ◎ | × | 日本語非対応 |
| GMO ペイメント | 要問合せ | 有料 | ○ | ◎ | 法人向け、個人開発に不向き |

---

## 10. アーキテクチャ設計

### レイヤー構成

```
┌─────────────────────────────────────────────────────┐
│  UI Layer (Pages / Widgets / Dialogs)               │
│  - Flutter Widgets                                   │
│  - Material Design 3                                 │
│  - Catppuccin カラーテーマ                            │
├─────────────────────────────────────────────────────┤
│  State Layer (Providers)                             │
│  - flutter_riverpod                                  │
│  - StateNotifier / AsyncNotifier                     │
├─────────────────────────────────────────────────────┤
│  Service Layer (Business Logic)                      │
│  - DreamService, GoalService, TaskService            │
│  - FeedbackService, InviteService, StripeService     │
│  - TrialLimitService, TutorialService                │
├─────────────────────────────────────────────────────┤
│  Data Layer (Persistence)                            │
│  - Drift (SQLite ORM) - 構造化データ                  │
│  - SharedPreferences - 設定・状態                     │
│  - GitHub Gist - リモート設定                         │
├─────────────────────────────────────────────────────┤
│  External Services                                   │
│  - Google Apps Script (フィードバック / Stripe)        │
│  - Stripe (決済)                                     │
│  - SonarCloud (品質管理)                              │
│  - GitHub Actions (CI/CD)                            │
│  - GitHub Pages (ホスティング)                        │
└─────────────────────────────────────────────────────┘
```

### データモデルの階層構造

```
夢 (Dream)
 └── 目標 (Goal) [1:N]
      └── タスク (Task) [1:N]
           └── 活動ログ (StudyLog) [1:N]

書籍 (Book) ── スケジュール ──→ ガントチャート上で可視化
星座 (Constellation) ←── 活動ログの蓄積で星が輝く
```

---

## 11. 技術選定の比較表

### 総合コスト比較

| サービス | 月額コスト | 備考 |
|---------|----------|------|
| GitHub（リポジトリ） | ¥0 | Private リポジトリ無料 |
| GitHub Pages | ¥0 | 静的サイトホスティング |
| GitHub Actions | ¥0 | 2,000分/月の無料枠内 |
| GitHub Gist | ¥0 | リモート設定管理 |
| SonarCloud | ¥0 | 無料枠内 |
| Google Apps Script | ¥0 | サーバーレスバックエンド |
| Google スプレッドシート | ¥0 | フィードバック・問い合わせデータ保存 |
| Stripe | ¥0 | 決済発生時のみ手数料 |
| **合計** | **¥0/月** | **ユーザーがいなければコスト 0** |

### 「サーバーレス」アーキテクチャの実現

本プロジェクトは**自前のサーバーを一切持たない完全サーバーレス構成**を実現しています:

| 機能 | 従来の実装 | 本プロジェクトの実装 |
|------|----------|------------------|
| データベース | クラウド DB（Firebase, Supabase） | ブラウザ内 SQLite（Drift） |
| バックエンド API | Express / FastAPI / Cloud Functions | Google Apps Script |
| 設定管理 | Firebase Remote Config | GitHub Gist |
| ホスティング | AWS / GCP / Vercel | GitHub Pages |
| CI/CD | Jenkins / CircleCI | GitHub Actions |
| 決済 | 自前決済 or Stripe SDK | Stripe Checkout（ホスト型） |

---

## 12. 開発で得た知見・教訓

### 成功した判断

1. **Flutter Web の採用** — 単一コードベースで Web + モバイル対応を実現。体験版 Web アプリとしてユーザーへのリーチが容易
2. **GitHub エコシステムの最大活用** — Pages / Actions / Gist を組み合わせ、月額コスト 0 円でプロダクション環境を構築
3. **SonarCloud の CI 統合** — プッシュごとに自動解析され、セキュリティ・品質の劣化を早期検知
4. **Claude Code との AI ペアプログラミング** — 個人開発でありながら、高品質なコード・テスト・ドキュメントを効率的に生産

### 注意すべきポイント

1. **GoRouter のシングルトン問題** — テスト間でルーター状態がリークする。テストヘルパーで状態の復旧ロジックを共通化して対処
2. **Drift の `isNull`/`isNotNull` 競合** — flutter_test と名前が衝突するため `hide` が必要
3. **GitHub Actions の並列実行** — SonarCloud と Integration Test が同時にコミットすると git push 競合が発生する
4. **SharedPreferences のテスト初期値** — 新機能（オンボーディング等）追加時に `setMockInitialValues` の更新漏れでテストが失敗しやすい。共通ヘルパーで一元管理して対策
5. **ドロワーの固定領域と ListView の重なり** — テスト環境の画面サイズが小さい場合にタップ判定が失敗する。共通ヘルパー `navigateViaDrawerInTest` で恒久対策

### 今後の拡張候補

| 機能 | 技術候補 | 優先度 |
|------|---------|--------|
| ユーザー認証 | Firebase Auth | サブスク本格化時 |
| サーバーサイド DB | Supabase / Firebase | マルチデバイス同期時 |
| プッシュ通知 | Firebase Cloud Messaging | リマインダー機能追加時 |
| テナント分離 | GitHub Gist + 機能フラグ | 案件対応時 |

---

## 追加ナレッジ（2026年3月 追記）

### スクロール方式の選定

| 方式 | 利点 | 欠点 | 採用 |
|---|---|---|---|
| InteractiveViewer | 2軸ズーム対応 | タッチ遅延（1-2フレーム） | 不採用 |
| **共有ScrollController** | **ネイティブ物理演算、指追従が完全同期** | 横/縦を別々に管理 | **採用** |
| TwoDimensionalScrollView | Flutter公式2Dスクロール | 固定ヘッダー非対応、未成熟 | 不採用 |

**選定理由**: ガントチャートでは横スクロールが最頻出操作。InteractiveViewer はジェスチャ→Controller→Listener の間接同期で遅延が発生するため、ScrollController の直接共有方式がベスト。

### ラベル管理の設計

| 方式 | 利点 | 欠点 | 採用 |
|---|---|---|---|
| JSONファイル外出し | 非開発者でも編集可能 | 型安全性なし、テストでアセット読み込みがハング | 不採用 |
| Flutter Intl (ARB) | 公式多言語対応 | 設定が重い、単一言語では過剰 | 不採用 |
| **Dart静的定数クラス** | **型安全、const 対応、コンパイル時エラー検出** | Dart知識が必要 | **採用** |

**選定理由**: `app_labels.dart` に `static const` で全UIテキストを集約。変数名のtypoはコンパイルエラーで検出でき、`const` ウィジェットも維持可能。約550定数を1ファイルで管理。

### 通知システムの設計

| 方式 | 利点 | 欠点 | 採用 |
|---|---|---|---|
| Firebase Cloud Messaging | プッシュ通知対応 | インフラ依存、Web制約あり | 不採用 |
| **アプリ内DB + JSONアセット** | **インフラ非依存、即時反映** | プッシュ通知不可 | **採用** |

**設計**: 3種類の通知（リマインダー/実績/開発者通知）を `notifications` テーブルで統合管理。開発者通知は `announcements.json` とDBを完全同期する方式（JSONを正として毎回全削除→再作成）。

### クラウド同期の設計

| 方式 | 利点 | 欠点 | 採用 |
|---|---|---|---|
| リアルタイム同期 (Firestore listener) | 常時最新 | 帯域消費大、オフライン複雑 | 不採用 |
| **タイムスタンプ比較 + 全量同期** | **シンプル、確実** | リアルタイム性なし | **採用** |

**設計**: アプリ起動時にクラウドの `updatedAt` とローカルの `cloud_last_sync_ms`（SharedPreferences）を比較。クラウドが新しければダウンロード、ローカルが新しければアップロード。データ変更時は3秒デバウンスで自動アップロード。

### 体験版制限の設計

| 方式 | 初期検討 | 最終採用 |
|---|---|---|
| 目標の制限単位 | 各夢ごとN個 | **全体でN個**（ユーザーに分かりやすい） |
| 解除方式 | 課金のみ | **フィードバック送信で段階解除** + プレミアム契約 |
| 開発者モード | なし | **認証メールアドレスで判定** |

**レベル別制限値**:

| Level | 夢 | 目標 | タスク/目標 | 書籍 |
|---|---|---|---|---|
| 0 | 1 | 3 | 3 | 3 |
| 1 | 2 | 5 | 5 | 4 |
| 2 | 3 | 8 | 8 | 5 |
| 3+ | 無制限 | 無制限 | 無制限 | 無制限 |

### Claude Code 習熟度レベル

| Level | 構成 | 効果 |
|---|---|---|
| 1 | Raw Prompting | 毎回手順を手動入力 |
| 2 | CLAUDE.md | ルール自動読み込み |
| **3** | **+ Skills** | **オンデマンド手順注入（トークン-64%）** |
| **4** | **+ Hooks** | **品質チェック100%自動化** |
| **5** | **+ Agents** | **並行レビュー（トークン-70%）** |

**実測値**: Level 2 → Level 5 で毎セッション読み込み量 16,574 → 5,161 bytes（-69%）。月間トークン消費 282,800 → 90,000（-68%）。

### CustomPainter の最適化パターン

```dart
// NG: paint() 内で毎フレーム生成
void paint(Canvas canvas, Size size) {
  final paint = Paint()..color = Colors.red;  // 毎回 new
  canvas.drawLine(..., paint);
}

// OK: コンストラクタまたは static final でキャッシュ
class MyPainter extends CustomPainter {
  static final _paint = Paint()..color = Colors.red;

  void paint(Canvas canvas, Size size) {
    canvas.drawLine(..., _paint);  // 再利用
  }
}
```

### N+1 クエリの回避パターン

```dart
// NG: ループ内でDB問い合わせ
for (final goal in goals) {
  final tasks = await taskDao.getByGoalId(goal.id);  // N回
}

// OK: 一括取得→メモリ上でグルーピング
final allTasks = await taskService.getAllTasks();  // 1回
final tasksByGoal = <String, List<Task>>{};
for (final task in allTasks) {
  tasksByGoal.putIfAbsent(task.goalId, () => []).add(task);
}
```

---

> **最終更新日**: 2026年3月30日
>
> **作成**: 須山 哲平 + Claude Code（AI ペアプログラミング）
