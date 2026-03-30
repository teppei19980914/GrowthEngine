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

import '../app_version.dart';
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
import '../l10n/app_labels.dart';
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
        _SectionHeader(title: AppLabels.settingsAppearance, icon: Icons.palette_outlined),
        Card(
          child: SwitchListTile(
            title: const Text(AppLabels.settingsDarkMode),
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
        _SectionHeader(title: AppLabels.settingsNotifications, icon: Icons.notifications_outlined),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(AppLabels.settingsAchievementNotif),
                subtitle: const Text(AppLabels.settingsAchievementNotifDesc),
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
                title: const Text(AppLabels.settingsReleaseNotes),
                subtitle: const Text(AppLabels.settingsReleaseNotesDesc),
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
        _SectionHeader(title: AppLabels.settingsDataManagement, icon: Icons.storage_outlined),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.file_upload_outlined,
                  color: colors.accent,
                ),
                title: const Text(AppLabels.settingsExportData),
                subtitle: const Text(
                  AppLabels.settingsExportDesc,
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
                  AppLabels.settingsImportData,
                  style: TextStyle(
                    color: isPremium ? null : colors.textMuted,
                  ),
                ),
                subtitle: Text(
                  isPremium ? AppLabels.settingsImportRestoreDesc : AppLabels.settingsImportPremiumOnly,
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
                  AppLabels.settingsDeleteAll,
                  style: TextStyle(color: colors.error),
                ),
                subtitle: const Text(AppLabels.settingsDeleteWarning),
                onTap: () => _clearAllData(context, ref),
              ),
              // クラウドデータ復元（Web + サインイン済み）
              if (kIsWeb && FirestoreSyncService().isSignedIn) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.cloud_download, color: colors.success),
                  title: const Text(AppLabels.settingsCloudRestore),
                  subtitle: const Text(AppLabels.settingsCloudRestoreDesc),
                  onTap: () => _restoreFromCloud(context, ref),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // アカウント（Web限定）
        if (kIsWeb) ...[
          _SectionHeader(title: AppLabels.settingsAccount, icon: Icons.person_outlined),
          _AccountCard(ref: ref, colors: colors),
          const SizedBox(height: 24),
        ],

        // 招待プラン
        _InviteStatusCard(ref: ref, colors: colors),

        // アップグレード（体験版かつサブスク・トライアル未加入時のみ）
        if (isTrialMode && !isPremium) ...[
          _SectionHeader(
              title: AppLabels.settingsUpgradeSection, icon: Icons.rocket_launch),
          Card(
            child: ListTile(
              leading: Icon(Icons.star, color: colors.accent),
              title: const Text(AppLabels.settingsUpgradeTitle),
              subtitle: const Text(AppLabels.settingsUpgradeDesc),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: colors.textMuted),
              onTap: () => showUpgradeDialog(context),
            ),
          ),
          const SizedBox(height: 24),
        ],


        // バージョン情報
        _SectionHeader(title: AppLabels.settingsAppInfo, icon: Icons.info_outlined),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.apps),
                title: Text(AppLabels.appName),
                subtitle: Text(AppLabels.settingsAppSubtitle),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  isPremium ? Icons.workspace_premium : Icons.rocket_launch,
                  color: isPremium ? colors.warning : colors.accent,
                ),
                title: const Text(AppLabels.settingsPlan),
                subtitle: Text(_getPlanName(ref)),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text(AppLabels.settingsVersion),
                subtitle: Text(appVersion),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.update),
                title: Text(AppLabels.settingsLastDeploy),
                subtitle: Text(deployedAt),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.flutter_dash),
                title: const Text('Flutter'),
                subtitle: const Text(AppLabels.settingsPlatform),
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



  Future<void> _restoreFromCloud(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppLabels.settingsCloudRestore),
        content: const Text(
          AppLabels.settingsCloudRestoreConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppLabels.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppLabels.settingsRestoreButton),
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
          const SnackBar(content: Text(AppLabels.cloudNoBackup)),
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
        const SnackBar(content: Text(AppLabels.cloudRestored)),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLabels.settingsRestoreError('$e'))),
      );
    }
  }

  String _getPlanName(WidgetRef ref) {
    // 招待プラン
    final prefs = ref.watch(sharedPreferencesProvider);
    final inviteService = InviteService(prefs);
    final inviteStatus = inviteService.getStatus();
    if (inviteStatus.isActive) {
      return AppLabels.settingsInvitePlanDays(inviteStatus.remainingDays ?? 0);
    }

    // プレミアムプラン
    if (isPremium) {
      if (kIsWeb) {
        final syncService = FirestoreSyncService();
        return syncService.isSignedIn
            ? AppLabels.settingsPremiumPlanAuth
            : AppLabels.settingsPremiumPlanNoAuth;
      }
      return AppLabels.settingsPremiumPlan;
    }

    // スタータープラン
    return AppLabels.settingsStarterPlan;
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
          SnackBar(content: Text(AppLabels.settingsExportSuccess(fileName))),
        );
      }
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLabels.settingsExportError('$e'))),
      );
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    if (isTrialMode && !isPremium) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppLabels.importUnavailable),
          content: Text(
            '${AppLabels.importUnavailableMsg}\n'
            '${AppLabels.settingsImportUpgradeMsg}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppLabels.btnClose),
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
            AppLabels.importError(validation.errorMessage ?? ''),
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppLabels.importConfirmTitle),
        content: Text(
          '${AppLabels.importConfirmMsg}\n'
          '${AppLabels.settingsImportOverwriteWarning}\n\n'
          '${AppLabels.settingsImportCounts(
            dreams: validation.counts['dreams'] ?? 0,
            goals: validation.counts['goals'] ?? 0,
            tasks: validation.counts['tasks'] ?? 0,
            books: validation.counts['books'] ?? 0,
            studyLogs: validation.counts['study_logs'] ?? 0,
            notifications: validation.counts['notifications'] ?? 0,
          )}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppLabels.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppLabels.importButton),
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
            AppLabels.settingsImportResult(
              dreams: result.dreamCount,
              goals: result.goalCount,
              tasks: result.taskCount,
              books: result.bookCount,
              logs: result.studyLogCount,
            ),
          ),
        ),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLabels.importError('$e'))),
      );
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppLabels.settingsDeleteAll),
        content: const Text(
          AppLabels.settingsDeleteConfirmMsg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppLabels.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppLabels.btnDelete),
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
        const SnackBar(content: Text(AppLabels.settingsDeleteSuccess)),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLabels.settingsDeleteError('$e'))),
      );
    }
  }
}

/// 招待プラン状態カード.
///
/// 招待コードが有効な場合のみ表示する.
/// アカウントカード.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.ref, required this.colors});

  final WidgetRef ref;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final syncService = FirestoreSyncService();
    final isLinked = syncService.isLinked;
    final email = syncService.email;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isLinked ? Icons.verified_user : Icons.person_outline,
              color: isLinked ? colors.success : colors.warning,
            ),
            title: Text(isLinked ? AppLabels.authLinked : AppLabels.settingsAnonymousUser),
            subtitle: Text(
              isLinked
                  ? email ?? ''
                  : AppLabels.settingsLinkEmailDesc,
            ),
          ),
          if (!isLinked) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _linkAccount(context),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text(AppLabels.settingsLinkEmailButton),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _linkAccount(BuildContext context) async {
    final result = await showCloudAuthDialog(context);
    if (result == null || result == CloudAuthResult.skipped) return;
    if (!context.mounted) return;

    final syncService = FirestoreSyncService();
    final exportService = ref.read(dataExportServiceProvider);

    if (result == CloudAuthResult.loggedIn) {
      // ログイン成功 → クラウドからデータを自動復元
      try {
        final json = await syncService.downloadData();
        if (json != null) {
          await exportService.importData(json);
          ref.invalidate(dreamListProvider);
          ref.invalidate(goalListProvider);
          ref.invalidate(bookListProvider);
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppLabels.cloudLoginRestored)),
        );
      } on Exception {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppLabels.cloudLoginRestoreFailed)),
        );
      }
    } else {
      // アカウント連携成功 → ローカルデータをアップロード
      final json = await exportService.exportData();
      await syncService.uploadData(json);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppLabels.cloudAccountLinked)),
      );
    }
    (context as Element).markNeedsBuild();
  }
}

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
          title: AppLabels.settingsInvitePlanSection,
          icon: Icons.card_giftcard_outlined,
        ),
        Card(
          child: ListTile(
            leading: Icon(
              inviteStatus.isActive ? Icons.verified : Icons.timer_off,
              color: inviteStatus.isActive ? colors.success : colors.error,
            ),
            title: Text(
              inviteStatus.isActive ? AppLabels.settingsInviteActive : AppLabels.settingsInviteExpired,
            ),
            subtitle: Text(
              inviteStatus.isActive
                  ? AppLabels.settingsInviteActiveDesc(
                      inviteStatus.name ?? '',
                      inviteStatus.remainingDays ?? 0,
                    )
                  : AppLabels.settingsInviteExpiredDesc,
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
