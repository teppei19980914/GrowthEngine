/// アプリ使い方ガイドダイアログ.
library;

import 'package:flutter/material.dart';

/// アプリ使い方ガイドダイアログを表示する.
Future<void> showAppGuideDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _AppGuideDialog(),
  );
}

class _AppGuideDialog extends StatefulWidget {
  const _AppGuideDialog();

  @override
  State<_AppGuideDialog> createState() => _AppGuideDialogState();
}

class _AppGuideDialogState extends State<_AppGuideDialog> {
  int _currentPage = 0;

  static const _pages = <_GuidePage>[
    _GuidePage(
      icon: Icons.auto_awesome,
      title: 'ステップ1: 夢を登録',
      description: 'まずは「夢」ページで、あなたの大きな目標や夢を登録しましょう。\n\n'
          '例: 「ITエンジニアになる」「資格を取得する」',
    ),
    _GuidePage(
      icon: Icons.flag,
      title: 'ステップ2: 目標を設定',
      description: '「3W1H 目標」ページで、夢を実現するための具体的な目標を設定します。\n\n'
          '- What（何を）\n'
          '- Why（なぜ）\n'
          '- When（いつまでに）\n'
          '- How（どうやって）',
    ),
    _GuidePage(
      icon: Icons.view_timeline,
      title: 'ステップ3: タスクを管理',
      description: '「ガントチャート」ページで、目標に紐づくタスクを作成し、'
          'スケジュールを管理します。\n\n'
          'タスクをタップすると学習ログの記録やタイマーも使えます。',
    ),
    _GuidePage(
      icon: Icons.menu_book,
      title: 'ステップ4: 書籍を管理',
      description: '「書籍」ページで学習に使う書籍を登録できます。\n\n'
          '読書の進捗管理や、読了時の要約・感想の記録ができます。',
    ),
    _GuidePage(
      icon: Icons.bar_chart,
      title: 'ステップ5: 統計で振り返り',
      description: '「統計」ページで学習の実績を確認できます。\n\n'
          '- 学習時間・日数の推移\n'
          '- 連続学習ストリーク\n'
          '- 目標別・書籍別の統計',
    ),
    _GuidePage(
      icon: Icons.stars,
      title: 'ステップ6: 星座で成長を実感',
      description: '「星座」ページでは、学習の積み重ねが星座として可視化されます。\n\n'
          '夢ごとに星座が割り当てられ、学習するほど星が輝きます。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_currentPage];
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _pages.length - 1;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('ユメログの使い方')),
          Text(
            '${_currentPage + 1} / ${_pages.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              page.icon,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              page.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              page.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentPage
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (!isFirst)
          TextButton(
            onPressed: () => setState(() => _currentPage--),
            child: const Text('戻る'),
          ),
        if (isFirst)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        if (!isLast)
          FilledButton(
            onPressed: () => setState(() => _currentPage++),
            child: const Text('次へ'),
          ),
        if (isLast)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('はじめる'),
          ),
      ],
    );
  }
}

class _GuidePage {
  const _GuidePage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
