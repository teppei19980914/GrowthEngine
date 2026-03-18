/// 通知ボタンウィジェット.
///
/// AppBarに配置する通知アイコンボタン。未読バッジを表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// 通知ボタン.
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
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotificationPopup(context, ref),
          tooltip: '通知',
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

  void _showNotificationPopup(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => const _NotificationPopup(),
    );
  }
}

/// 通知ポップアップダイアログ.
class _NotificationPopup extends ConsumerWidget {
  const _NotificationPopup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(allNotificationsProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.notifications_outlined, size: 22),
          const SizedBox(width: 8),
          const Text('通知'),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final service = ref.read(notificationServiceProvider);
              await service.markAllAsRead();
              ref.invalidate(unreadCountProvider);
              ref.invalidate(allNotificationsProvider);
            },
            child: const Text('全て既読'),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: notifAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 48, color: colors.textMuted),
                    const SizedBox(height: 8),
                    Text('新しい通知はここに届きます',
                        style: TextStyle(color: colors.textMuted)),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final n = notifications[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    n.notificationType == model.NotificationType.achievement
                        ? Icons.emoji_events
                        : Icons.info_outline,
                    color: n.isRead ? colors.textMuted : colors.warning,
                    size: 20,
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.message, style: const TextStyle(fontSize: 11)),
                      Text(
                        dateFormat.format(n.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!n.isRead) {
                      final service = ref.read(notificationServiceProvider);
                      await service.markAsRead(n.id);
                      ref.invalidate(unreadCountProvider);
                      ref.invalidate(allNotificationsProvider);
                    }
                  },
                );
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
