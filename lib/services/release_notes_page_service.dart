/// リリース履歴のHTMLページを生成するサービス.
library;

import '../app_version.dart';
import '../l10n/app_labels.dart';

/// リリース履歴をHTMLページとして生成する.
///
/// [isDarkMode] が true の場合はダークテーマ、false の場合はライトテーマで生成する.
String generateReleaseNotesHtml({bool isDarkMode = true}) {
  // テーマに応じたカラー定義
  final bg = isDarkMode ? '#1e1e2e' : '#eff1f5';
  final headerBg = isDarkMode
      ? 'linear-gradient(135deg, #1e1e2e 0%, #313244 100%)'
      : 'linear-gradient(135deg, #dce0e8 0%, #ccd0da 100%)';
  final textColor = isDarkMode ? '#cdd6f4' : '#4c4f69';
  final mutedColor = isDarkMode ? '#a6adc8' : '#6c6f85';
  final cardBg = isDarkMode ? '#313244' : '#ffffff';
  final accent = isDarkMode ? '#89b4fa' : '#1e66f5';
  final green = isDarkMode ? '#a6e3a1' : '#40a02b';
  final borderColor = isDarkMode ? '#45475a' : '#ccd0da';
  final footerColor = isDarkMode ? '#45475a' : '#bcc0cc';
  final buf = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="ja"><head>')
    ..writeln('<meta charset="UTF-8">')
    ..writeln('<meta name="viewport" content="width=device-width,initial-scale=1">')
    ..writeln('<title>${AppLabels.appName} - アップデート情報</title>')
    ..writeln('<style>')
    ..writeln('''
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: 'Hiragino Sans', 'Noto Sans JP', -apple-system, sans-serif;
  background: $bg; color: $textColor; line-height: 1.8;
}
.header {
  background: $headerBg;
  padding: 40px 20px; text-align: center;
  border-bottom: 3px solid $accent;
}
.header h1 { font-size: 1.6em; color: $textColor; margin-bottom: 4px; }
.header p { color: $mutedColor; font-size: 0.9em; }
.container { max-width: 760px; margin: 0 auto; padding: 32px 20px; }
.version-card {
  background: $cardBg; border-radius: 12px; padding: 24px;
  margin-bottom: 24px; border-left: 4px solid $accent;
}
.version-header {
  display: flex; align-items: center; gap: 12px;
  margin-bottom: 12px; flex-wrap: wrap;
}
.version-tag {
  background: $accent; color: $bg; padding: 4px 12px;
  border-radius: 16px; font-weight: bold; font-size: 0.9em;
}
.version-date { color: $mutedColor; font-size: 0.85em; }
.version-latest {
  background: $green; color: $bg; padding: 2px 8px;
  border-radius: 8px; font-size: 0.75em; font-weight: bold;
}
.notes-list { list-style: none; padding: 0; }
.notes-list li {
  padding: 6px 0 6px 24px; position: relative;
  color: $mutedColor; font-size: 0.95em;
}
.notes-list li::before {
  content: '\\2714'; position: absolute; left: 0;
  color: $green; font-size: 0.85em;
}
.footer {
  text-align: center; padding: 24px; color: $footerColor;
  font-size: 0.8em; border-top: 1px solid $borderColor;
}
a { color: $accent; text-decoration: none; }
a:hover { text-decoration: underline; }
''')
    ..writeln('</style></head><body>')
    ..writeln('<div class="header">')
    ..writeln('<h1>${AppLabels.appName} アップデート情報</h1>')
    ..writeln('<p>現在のバージョン: v$appVersion</p>')
    ..writeln('</div>')
    ..writeln('<div class="container">');

  for (var i = 0; i < releaseHistory.length; i++) {
    final entry = releaseHistory[i];
    final isLatest = i == 0;

    buf.writeln('<div class="version-card">');
    buf.writeln('<div class="version-header">');
    buf.writeln('<span class="version-tag">v${_escapeHtml(entry.version)}</span>');
    buf.writeln('<span class="version-date">${_escapeHtml(entry.date)}</span>');
    if (isLatest) {
      buf.writeln('<span class="version-latest">最新</span>');
    }
    buf.writeln('</div>');
    buf.writeln('<ul class="notes-list">');
    for (final note in entry.notes) {
      buf.writeln('<li>${_escapeHtml(note)}</li>');
    }
    buf.writeln('</ul>');
    buf.writeln('</div>');
  }

  buf
    ..writeln('</div>')
    ..writeln('<div class="footer">')
    ..writeln('<p>&copy; 2026 ${AppLabels.appName} (YumeHashi)</p>')
    ..writeln('</div>')
    ..writeln('</body></html>');

  return buf.toString();
}

String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
