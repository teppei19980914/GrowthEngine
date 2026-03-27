/// 受信ボックスボタンウィジェット.
///
/// AppBarに配置する受信ボックスアイコン。未読バッジを表示する.
/// タップで受信ボックスポップアップを開く.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/notification.dart' as model;
import '../../providers/service_providers.dart';
import '../../theme/app_theme.dart';

/// 未読通知数Provider.
final unreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCount();
});

/// 全通知Provider.
final allNotificationsProvider =
    FutureProvider<List<model.Notification>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getAllNotifications();
});

/// 受信ボックスボタン.
class NotificationButton extends ConsumerWidget {
  /// NotificationButtonを作成する.
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.inbox_outlined),
          onPressed: () => _showInboxPopup(context, ref),
          tooltip: '受信ボックス',
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).appColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showInboxPopup(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => const _InboxPopup(),
    );
  }
}

/// 受信ボックスポップアップ.
class _InboxPopup extends ConsumerWidget {
  const _InboxPopup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(allNotificationsProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      title: Row(
        children: [
          Icon(Icons.inbox, size: 22, color: colors.accent),
          const SizedBox(width: 8),
          const Text('受信ボックス'),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              final service = ref.read(notificationServiceProvider);
              await service.markAllAsRead();
              ref.invalidate(unreadCountProvider);
              ref.invalidate(allNotificationsProvider);
            },
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('全て既読'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 420,
        child: notifAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 48, color: colors.textMuted),
                    const SizedBox(height: 8),
                    Text('受信ボックスは空です',
                        style: TextStyle(color: colors.textMuted)),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _InboxItem(notification: n);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('エラーが発生しました')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// 受信ボックスの1件分のアイテム.
class _InboxItem extends ConsumerWidget {
  const _InboxItem({required this.notification});

  final model.Notification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final isUnread = !notification.isRead;
    final dateFormat = DateFormat('MM/dd');
    final n = notification;

    // 通知種別に応じたアイコン・色
    final (IconData icon, Color iconColor) = switch (n.notificationType) {
      model.NotificationType.reminder => (
          Icons.alarm,
          isUnread ? colors.error : colors.textMuted,
        ),
      model.NotificationType.achievement => (
          Icons.emoji_events,
          isUnread ? colors.warning : colors.textMuted,
        ),
      model.NotificationType.system => (
          Icons.campaign,
          isUnread ? colors.accent : colors.textMuted,
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? colors.accent.withAlpha(12) : null,
        border: Border(
          bottom: BorderSide(color: colors.border.withAlpha(40)),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          n.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          n.message,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          dateFormat.format(n.createdAt),
          style: TextStyle(fontSize: 10, color: colors.textMuted),
        ),
        onTap: () => _onTap(context, ref),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    // 既読にする
    if (!notification.isRead) {
      final service = ref.read(notificationServiceProvider);
      await service.markAsRead(notification.id);
      ref.invalidate(unreadCountProvider);
      ref.invalidate(allNotificationsProvider);
    }

    if (!context.mounted) return;

    // リマインダー → ポップアップを閉じてガントチャート/目標ページに遷移
    if (notification.notificationType == model.NotificationType.reminder) {
      final isGoal = notification.dedupKey.startsWith('reminder:goal:');
      // 受信ボックスポップアップを閉じる → さらに親ダイアログも閉じる
      Navigator.of(context).pop(); // InboxPopup を閉じる
      if (!context.mounted) return;
      if (isGoal) {
        context.go('/goals');
      } else {
        context.go('/gantt');
      }
      return;
    }

    // 実績・お知らせ → メッセージ詳細を表示
    await showDialog<void>(
      context: context,
      builder: (context) => _NotificationDetailDialog(
        notification: notification,
      ),
    );
  }
}

/// 通知詳細ダイアログ.
class _NotificationDetailDialog extends StatelessWidget {
  const _NotificationDetailDialog({required this.notification});

  final model.Notification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final n = notification;

    final (IconData icon, Color iconColor) = switch (n.notificationType) {
      model.NotificationType.reminder => (Icons.alarm, colors.error),
      model.NotificationType.achievement => (
          Icons.emoji_events,
          colors.warning,
        ),
      model.NotificationType.system => (Icons.campaign, colors.accent),
    };

    final typeLabel = switch (n.notificationType) {
      model.NotificationType.reminder => 'リマインド',
      model.NotificationType.achievement => '実績',
      model.NotificationType.system => 'お知らせ',
    };

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(n.title, style: theme.textTheme.titleSmall),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリ + 日時
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(n.createdAt),
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(n.message, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
