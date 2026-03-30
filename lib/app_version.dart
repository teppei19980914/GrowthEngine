/// アプリのバージョン情報とリリース履歴.
///
/// バージョン更新時はこのファイルと pubspec.yaml の version を同時に更新する.
/// このファイルがリリースノートポップアップ・設定画面・リリース履歴画面の
/// 唯一のデータソース.
library;

/// アプリの現在バージョン番号.
///
/// pubspec.yaml の version と一致させること.
const appVersion = '1.0.0';

/// 最終デプロイ日時.
///
/// GitHub Actions の deploy.yml が自動的に書き換える.
/// ローカル開発時は手動更新不要（'---' が表示される）.
const deployedAt = '---';

/// リリース履歴（新しい順）.
///
/// バージョン更新時は先頭にエントリを追加する.
/// - [version]: バージョン番号
/// - [date]: リリース日（yyyy-MM-dd）
/// - [notes]: 変更内容の一覧
///
/// 最新エントリ（先頭）がリリースノートポップアップに使用される.
const releaseHistory = <ReleaseEntry>[
  ReleaseEntry(
    version: '1.0.0',
    date: '2026-04-01',
    notes: [
      '初回リリース',
    ],
  ),
];

/// 現在バージョンのリリースノート（ポップアップ表示用）.
List<String> get releaseNotes => releaseHistory.first.notes;

/// リリース履歴の1エントリ.
class ReleaseEntry {
  /// ReleaseEntryを作成する.
  const ReleaseEntry({
    required this.version,
    required this.date,
    required this.notes,
  });

  /// バージョン番号.
  final String version;

  /// リリース日（yyyy-MM-dd）.
  final String date;

  /// 変更内容の一覧.
  final List<String> notes;
}
