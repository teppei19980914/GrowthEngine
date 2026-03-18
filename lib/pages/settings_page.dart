/// 設定ページ.
///
/// テーマ切替、通知設定、データエクスポート/インポート/全削除、
/// バージョン情報を提供する.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dialogs/dream_discovery_dialog.dart';
import '../dialogs/feedback_dialog.dart';
import '../providers/book_providers.dart';
import '../providers/dream_providers.dart';
import '../providers/goal_providers.dart';
import '../dialogs/inquiry_dialog.dart';
import '../dialogs/upgrade_dialog.dart';
import '../services/file_save_service.dart' as file_io;
import '../services/inquiry_service.dart';
import '../providers/service_providers.dart';
import '../providers/theme_provider.dart';
import '../services/feedback_service.dart';
import '../services/trial_limit_service.dart' show isTrialMode, isPremium;
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

        // 招待プラン
        _InviteStatusCard(ref: ref, colors: colors),

        // アップグレード（体験版かつサブスク・トライアル未加入時のみ）
        if (isTrialMode && !isPremium) ...[
          _SectionHeader(
              title: 'プランのアップグレード', icon: Icons.rocket_launch),
          Card(
            child: ListTile(
              leading: Icon(Icons.star, color: colors.accent),
              title: const Text('もっと自由に、もっと先へ'),
              subtitle: const Text('ワンコインで全機能を利用可能'),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: colors.textMuted),
              onTap: () => showUpgradeDialog(context),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // フィードバック・制限解除
        _SectionHeader(
            title: 'フィードバック', icon: Icons.rate_review_outlined),
        _FeedbackCard(ref: ref, colors: colors),
        const SizedBox(height: 24),

        // お問い合わせ
        _SectionHeader(
            title: 'お問い合わせ', icon: Icons.mail_outlined),
        _InquiryCard(ref: ref, colors: colors),
        const SizedBox(height: 24),

        // ヘルプ
        _SectionHeader(title: 'ヘルプ', icon: Icons.help_outline),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.explore, color: colors.accent),
                title: const Text('やりたいこと発見ガイド'),
                subtitle: const Text('質問に答えてやりたいことを見つけよう'),
                onTap: () => _openDiscoveryGuide(context, ref),
              ),
              const Divider(height: 1),
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('特定商取引法に基づく表記'),
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://teppei19980914.github.io/GrowthEngine/tokushoho.html',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openDiscoveryGuide(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDreamDiscoveryDialog(context);
    if (result == null || !context.mounted) return;

    await ref.read(dreamListProvider.notifier).createDream(
          title: result.title,
          description: result.description,
          why: result.why,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${result.title}」を作成しました')),
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
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'yumelog_backup_$timestamp.json';

      final saved = await file_io.saveFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/json',
        allowedExtensions: ['json'],
      );

      if (!context.mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileNameをエクスポートしました')),
        );
      }
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
            'サブスクプランにアップグレードしてご利用ください。',
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

    final bytes = await file_io.pickFile(allowedExtensions: ['json']);
    if (bytes == null) return;

    final jsonString = utf8.decode(bytes);
    final service = ref.read(dataExportServiceProvider);
    final validation = service.validateJson(jsonString);

    if (!validation.valid) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'インポートに失敗しました: ${validation.errorMessage}',
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データをインポート'),
        content: Text(
          '以下のデータをインポートします。\n'
          '既存データは全て上書きされます。\n\n'
          '夢: ${validation.counts['dreams'] ?? 0}件\n'
          '目標: ${validation.counts['goals'] ?? 0}件\n'
          'タスク: ${validation.counts['tasks'] ?? 0}件\n'
          '書籍: ${validation.counts['books'] ?? 0}件\n'
          '活動ログ: ${validation.counts['study_logs'] ?? 0}件\n'
          '通知: ${validation.counts['notifications'] ?? 0}件',
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

    if (confirmed != true) return;

    try {
      final result = await service.importData(jsonString);

      // 全Providerを再読み込みしてUIに反映
      ref.invalidate(dreamListProvider);
      ref.invalidate(goalListProvider);
      ref.invalidate(bookListProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'インポート完了: 夢${result.dreamCount}件, '
            '目標${result.goalCount}件, '
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

      // 全Providerを再読み込みしてUIに反映
      ref.invalidate(dreamListProvider);
      ref.invalidate(goalListProvider);
      ref.invalidate(bookListProvider);

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
          if (isMax)
            ListTile(
              leading: Icon(Icons.lock_open, color: colors.success),
              title: const Text('無制限プラン利用中'),
              subtitle: const Text('制限は完全に解除されています'),
            )
          else ...[
            ListTile(
              leading: Icon(Icons.rate_review_outlined, color: colors.accent),
              title: const Text('フィードバックを送信'),
              subtitle: Text(
                isFeedbackMax
                    ? 'ご意見・ご要望をお聞かせください'
                    : 'ご意見を送信すると制限が解除されます'
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
            ),
            if (isFeedbackMax) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.star, color: colors.accent),
                title: const Text('無制限プランのご案内'),
                subtitle: const Text(
                  '全機能を制限なくご利用いただけます。',
                ),
                onTap: () => showUpgradeDialog(context),
              ),
            ],
          ],
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

/// 招待プラン状態カード.
///
/// 招待コードが有効な場合のみ表示する.
class _InviteStatusCard extends StatelessWidget {
  const _InviteStatusCard({required this.ref, required this.colors});

  final WidgetRef ref;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final inviteStatus = ref.watch(inviteStatusProvider);
    if (!inviteStatus.isActive && inviteStatus.expiredAt == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '招待プラン',
          icon: Icons.card_giftcard_outlined,
        ),
        Card(
          child: ListTile(
            leading: Icon(
              inviteStatus.isActive ? Icons.verified : Icons.timer_off,
              color: inviteStatus.isActive ? colors.success : colors.error,
            ),
            title: Text(
              inviteStatus.isActive ? '招待プラン利用中' : '招待プラン期限切れ',
            ),
            subtitle: Text(
              inviteStatus.isActive
                  ? '${inviteStatus.name ?? ""}　'
                      '残り${inviteStatus.remainingDays}日（全機能利用可能）'
                  : '有効期限が終了しました。'
                      '引き続きご利用いただくにはお問い合わせください。',
            ),
          ),
        ),
        SizedBox(height: inviteStatus.isActive ? 24 : 8),
        if (inviteStatus.isActive) ...[
          // 有効時はフィードバック前にスペースを入れる
        ] else ...[
          // 期限切れ時はお問い合わせを案内
          Card(
            child: ListTile(
              leading: Icon(Icons.mail_outlined, color: colors.accent),
              title: const Text('プラン延長のお問い合わせ'),
              subtitle: const Text('引き続き全機能をご利用いただけます'),
              onTap: () {
                final userKey = ref.read(remoteConfigProvider).name;
                showInquiryDialog(
                  context,
                  InquiryService(),
                  userKey: userKey.isNotEmpty ? userKey : null,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

/// お問い合わせカード.
class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.ref, required this.colors});

  final WidgetRef ref;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.mail_outlined, color: colors.accent),
        title: const Text('お問い合わせ'),
        subtitle: const Text('追加開発・案件のご相談など'),
        onTap: () {
          final userKey = ref.read(remoteConfigProvider).name;
          showInquiryDialog(
            context,
            InquiryService(),
            userKey: userKey.isNotEmpty ? userKey : null,
          );
        },
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
