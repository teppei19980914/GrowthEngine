/// 設定ページ.
///
/// テーマ切替、通知設定、データエクスポート/インポート/全削除、
/// バージョン情報を提供する.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/cloud_auth_dialog.dart';
import '../dialogs/upgrade_dialog.dart';
import '../providers/book_providers.dart';
import '../providers/dream_providers.dart';
import '../providers/goal_providers.dart';
import '../services/file_save_service.dart' as file_io;
import '../services/firestore_sync_service.dart';
import '../providers/service_providers.dart';
import '../providers/theme_provider.dart';
import '../services/invite_service.dart';
import '../services/trial_limit_service.dart' show isTrialMode, isPremium;
import '../theme/app_theme.dart';

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
          child: Column(
            children: [
              SwitchListTile(
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
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('リリース通知'),
                subtitle: const Text('新機能リリース時にお知らせを表示'),
                value: ref.watch(sharedPreferencesProvider).getBool('release_notes_enabled') ?? true,
                onChanged: (value) async {
                  await ref.read(sharedPreferencesProvider).setBool('release_notes_enabled', value);
                  (context as Element).markNeedsBuild();
                },
                secondary: const Icon(Icons.new_releases_outlined),
              ),
            ],
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
                subtitle: const Text(
                  '夢・目標・タスク・書籍・活動ログ・通知をJSON形式でバックアップ',
                ),
                onTap: () => _exportData(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.file_download_outlined,
                  color: isPremium ? colors.success : colors.textMuted,
                ),
                title: Text(
                  'データをインポート',
                  style: TextStyle(
                    color: isPremium ? null : colors.textMuted,
                  ),
                ),
                subtitle: Text(
                  isPremium ? 'バックアップから復元' : 'プレミアムプランで利用可能',
                  style: TextStyle(
                    color: isPremium ? null : colors.textMuted,
                  ),
                ),
                onTap: isPremium ? () => _importData(context, ref) : null,
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
              // プレミアム認証済み: クラウドデータ復元（Web限定）
              if (kIsWeb &&
                  isPremium &&
                  FirestoreSyncService().isSignedIn) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.cloud_download, color: colors.success),
                  title: const Text('クラウドからデータ復元'),
                  subtitle: const Text('バックアップからデータを復元します'),
                  onTap: () => _restoreFromCloud(context, ref),
                ),
              ],
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
              ListTile(
                leading: Icon(
                  isPremium ? Icons.workspace_premium : Icons.rocket_launch,
                  color: isPremium ? colors.warning : colors.accent,
                ),
                title: const Text('ご利用プラン'),
                subtitle: Text(_getPlanName(ref)),
              ),
              // プレミアム未認証: 認証の警告と認証ボタン（Web限定）
              if (kIsWeb &&
                  isPremium &&
                  !FirestoreSyncService().isSignedIn) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'データ保護のためにクラウド認証を設定してください。\n'
                    '未認証の場合、ブラウザのキャッシュクリアで'
                    '全データが失われます。',
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _setupCloudAuth(context, ref),
                      icon: const Icon(Icons.cloud_outlined, size: 18),
                      label: const Text('クラウド認証を設定する'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
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



  Future<void> _setupCloudAuth(BuildContext context, WidgetRef ref) async {
    final result = await showCloudAuthDialog(context);
    if (result == CloudAuthResult.success && context.mounted) {
      // 認証成功 → ローカルデータをアップロード
      final syncService = FirestoreSyncService();
      final exportService = ref.read(dataExportServiceProvider);
      final json = await exportService.exportData();
      await syncService.uploadData(json);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クラウド認証を設定し、データを保存しました')),
      );
      // UIを更新
      (context as Element).markNeedsBuild();
    }
  }

  Future<void> _restoreFromCloud(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クラウドからデータ復元'),
        content: const Text(
          'クラウドに保存されたデータでローカルデータを上書きします。\n'
          '現在のローカルデータは失われます。\n\n'
          '復元しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('復元する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final syncService = FirestoreSyncService();
      final json = await syncService.downloadData();

      if (json == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クラウドにバックアップデータが見つかりません')),
        );
        return;
      }

      final exportService = ref.read(dataExportServiceProvider);
      await exportService.importData(json);

      // 全Providerを更新
      ref.invalidate(dreamListProvider);
      ref.invalidate(goalListProvider);
      ref.invalidate(bookListProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クラウドからデータを復元しました')),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('復元に失敗しました: $e')),
      );
    }
  }

  String _getPlanName(WidgetRef ref) {
    // 招待プラン
    final prefs = ref.watch(sharedPreferencesProvider);
    final inviteService = InviteService(prefs);
    final inviteStatus = inviteService.getStatus();
    if (inviteStatus.isActive) {
      return '招待プラン（残り${inviteStatus.remainingDays}日）';
    }

    // プレミアムプラン
    if (isPremium) {
      if (kIsWeb) {
        final syncService = FirestoreSyncService();
        return syncService.isSignedIn
            ? 'プレミアムプラン（認証）'
            : 'プレミアムプラン（未認証）';
      }
      return 'プレミアムプラン';
    }

    // スタータープラン
    return 'スタータープラン';
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
    if (isTrialMode && !isPremium) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('インポート不可'),
          content: const Text(
            'スタータープランではデータのインポートはご利用いただけません。\n'
            'プレミアムプランにアップグレードしてご利用ください。',
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
                      '有効期限が終了しました。'
                      'プレミアムプランへのアップグレードで引き続き全機能をご利用いただけます。',
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
