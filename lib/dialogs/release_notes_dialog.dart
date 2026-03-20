/// リリースノートダイアログ.
///
/// 新バージョンのデプロイ時にユーザーに新機能を通知する.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// リリースノートダイアログを表示する.
Future<void> showReleaseNotesDialog(
  BuildContext context, {
  required String version,
  required List<String> notes,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReleaseNotesDialog(version: version, notes: notes),
  );
}

class _ReleaseNotesDialog extends StatelessWidget {
  const _ReleaseNotesDialog({
    required this.version,
    required this.notes,
  });

  final String version;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.new_releases_outlined,
              color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Text('バージョン $version'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '新機能・改善のお知らせ',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...notes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: colors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('確認しました'),
        ),
      ],
    );
  }
}
