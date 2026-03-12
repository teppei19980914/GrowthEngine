/// 設定ページ.
///
/// テーマ切替、通知設定、データエクスポート/インポート/全削除、
/// バージョン情報を提供する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dialogs/feedback_dialog.dart';
import '../dialogs/upgrade_dialog.dart';
import '../providers/service_providers.dart';
import '../providers/theme_provider.dart';
import '../services/feedback_service.dart';
import '../services/trial_limit_service.dart' show isTrialMode;
import '../theme/app_theme.dart';
import '../widgets/tutorial/tutorial_banner.dart';
import '../widgets/web/web_trial_banner.dart';

/// 通知有効/無効Provider.
final _notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationsEnabled;
});

/// 設定ページ.
class SettingsPage extends ConsumerWidget {
  /// SettingsPageを作成する.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final notifAsync = ref.watch(_notificationsEnabledProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // テーマ設定
        _SectionHeader(title: '外観', icon: Icons.palette_outlined),
        Card(
          child: SwitchListTile(
            title: const Text('ダークモード'),
            subtitle: Text(
              themeType == ThemeType.dark
                  ? 'Catppuccin Mocha'
                  : 'Catppuccin Latte',
            ),
            value: themeType == ThemeType.dark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
            secondary: Icon(
              themeType == ThemeType.dark ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 通知設定
        _SectionHeader(title: '通知', icon: Icons.notifications_outlined),
        Card(
          child: SwitchListTile(
            title: const Text('実績通知'),
            subtitle: const Text('実績達成時に通知を表示'),
            value: notifAsync.valueOrNull ?? true,
            onChanged: (value) async {
              final service = ref.read(notificationServiceProvider);
              await service.setNotificationsEnabled(value);
              ref.invalidate(_notificationsEnabledProvider);
            },
            secondary: const Icon(Icons.emoji_events_outlined),
          ),
        ),
        const SizedBox(height: 24),

        // データ管理
        _SectionHeader(title: 'データ管理', icon: Icons.storage_outlined),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.file_upload_outlined,
                  color: colors.accent,
                ),
                title: const Text('データをエクスポート'),
                subtitle: const Text('JSON形式でバックアップ'),
                onTap: () => _exportData(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.file_download_outlined,
                  color: colors.success,
                ),
                title: const Text('データをインポート'),
                subtitle: const Text('バックアップから復元'),
                onTap: () => _importData(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined,
                    color: colors.error),
                title: Text(
                  '全データを削除',
                  style: TextStyle(color: colors.error),
                ),
                subtitle: const Text('この操作は取り消せません'),
                onTap: () => _clearAllData(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // フィードバック・制限解除
        _SectionHeader(
            title: 'フィードバック', icon: Icons.rate_review_outlined),
        _FeedbackCard(ref: ref, colors: colors),
        const SizedBox(height: 24),

        // ヘルプ
        _SectionHeader(title: 'ヘルプ', icon: Icons.help_outline),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.school_outlined, color: colors.accent),
                title: const Text('チュートリアルを開始'),
                subtitle: const Text('実際に操作しながらアプリの使い方を体験'),
                onTap: () => _startTutorial(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('体験版の制限事項'),
                subtitle: const Text('Web体験版の制限と注意事項を確認'),
                onTap: () => _showTrialInfo(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // バージョン情報
        _SectionHeader(title: 'アプリ情報', icon: Icons.info_outlined),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.apps),
                title: Text('ユメログ'),
                subtitle: Text('夢実現支援アプリ'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text('バージョン'),
                subtitle: Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.flutter_dash),
                title: const Text('Flutter'),
                subtitle: const Text('クロスプラットフォーム対応'),
                trailing: Icon(
                  Icons.check_circle,
                  color: colors.success,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startTutorial(BuildContext context, WidgetRef ref) async {
    final tutorialState = ref.read(tutorialStateProvider);
    if (tutorialState.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('チュートリアルは既に実行中です')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チュートリアルを開始'),
        content: const Text(
          '実際にアプリを操作しながら基本的な使い方を体験します。\n\n'
          '画面上部のバナーに従って操作してください。\n'
          'チュートリアル中に作成したデータは、完了時に保持するか削除するかを選べます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('開始する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(tutorialStateProvider.notifier).start();

    if (!context.mounted) return;
    // ダッシュボードに戻る（チュートリアルはそこから始まる）
    GoRouter.of(context).go('/');
  }

  Future<void> _showTrialInfo(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!context.mounted) return;
    await showWebTrialDialog(context, prefs);
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(dataExportServiceProvider);
      final jsonString = await service.exportData();
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エクスポート完了'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonString,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エクスポートに失敗しました: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    if (isTrialMode) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('インポート不可'),
          content: const Text(
            'Web体験版ではデータのインポートはご利用いただけません。\n'
            'ネイティブアプリをダウンロードしてご利用ください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データをインポート'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'JSONデータを貼り付けてください...',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('インポート'),
          ),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty) return;

    try {
      final service = ref.read(dataExportServiceProvider);
      final result = await service.importData(controller.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'インポート完了: 目標${result.goalCount}件, '
            'タスク${result.taskCount}件, '
            '書籍${result.bookCount}件, '
            'ログ${result.studyLogCount}件',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('インポートに失敗しました: $e')),
      );
    }
    controller.dispose();
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全データを削除'),
        content: const Text(
          'すべてのデータを削除します。\nこの操作は取り消せません。\n本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(dataExportServiceProvider);
      await service.clearAllData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全データを削除しました')),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }
}

/// フィードバックカード.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.ref, required this.colors});

  final WidgetRef ref;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final feedbackService = ref.watch(feedbackServiceProvider);
    final level = feedbackService.unlockLevel;
    final isMax = feedbackService.isMaxLevel;
    final isFeedbackMax = feedbackService.isFeedbackMaxLevel;
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          // フィードバック送信ボタン
          if (!isFeedbackMax)
            ListTile(
              leading: Icon(Icons.rate_review_outlined, color: colors.accent),
              title: const Text('フィードバックを送信'),
              subtitle: Text(
                'ご意見を送信すると制限が解除されます'
                '（レベル$level / $feedbackUnlockableLevel）',
              ),
              onTap: () {
                final userKey = ref.read(remoteConfigProvider).name;
                showFeedbackDialog(
                  context,
                  feedbackService,
                  userKey: userKey.isNotEmpty ? userKey : null,
                );
              },
            )
          else if (isMax)
            ListTile(
              leading: Icon(Icons.lock_open, color: colors.success),
              title: const Text('無制限プラン利用中'),
              subtitle: const Text('制限は完全に解除されています'),
            )
          else
            ListTile(
              leading: Icon(Icons.star, color: colors.accent),
              title: const Text('無制限プランのご案内'),
              subtitle: const Text(
                'フィードバックによる解除は上限に達しました。\n'
                '無制限プランで全機能をご利用いただけます。',
              ),
              onTap: () => showUpgradeDialog(context),
            ),
          // プログレスバー
          if (!isMax) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: level / feedbackMaxLevel,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          isFeedbackMax ? colors.success : colors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'レベル$level / $feedbackMaxLevel',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// セクションヘッダー.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.appColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
