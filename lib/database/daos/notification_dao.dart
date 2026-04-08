/// 通知DAO.
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notifications_table.dart';

part 'notification_dao.g.dart';

/// NotificationのCRUD操作を提供するDAO.
@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationDaoMixin {
  /// NotificationDaoを作成する.
  NotificationDao(super.db);

  /// 全Notificationを取得する（作成日時降順）.
  Future<List<Notification>> getAll() =>
      (select(notifications)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// IDでNotificationを取得する.
  Future<Notification?> getById(String notificationId) =>
      (select(notifications)..where((t) => t.id.equals(notificationId)))
          .getSingleOrNull();

  /// 未読通知を取得する（作成日時降順）.
  Future<List<Notification>> getUnread() =>
      (select(notifications)
            ..where((t) => t.isRead.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// 未読通知数を返す.
  Future<int> getUnreadCount() async {
    final count = countAll();
    final query = selectOnly(notifications)
      ..addColumns([count])
      ..where(notifications.isRead.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// 指定種別の通知件数を返す.
  Future<int> countByType(String notificationType) async {
    final count = countAll();
    final query = selectOnly(notifications)
      ..addColumns([count])
      ..where(notifications.notificationType.equals(notificationType));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// 重複防止キーで存在チェックする.
  Future<bool> existsByDedupKey(String dedupKey) async {
    final query = select(notifications)
      ..where((t) => t.dedupKey.equals(dedupKey))
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Notificationを追加する.
  Future<void> insertNotification(NotificationsCompanion notification) =>
      into(notifications).insert(notification);

  /// 通知を既読にする.
  Future<bool> markAsRead(String notificationId) async {
    final count = await (update(notifications)
          ..where((t) => t.id.equals(notificationId)))
        .write(const NotificationsCompanion(isRead: Value(true)));
    return count > 0;
  }

  /// 全通知を既読にする.
  Future<int> markAllAsRead() =>
      (update(notifications)
            ..where((t) => t.isRead.equals(false)))
          .write(const NotificationsCompanion(isRead: Value(true)));

  /// 指定種別の通知を全削除する.
  Future<int> deleteByType(String notificationType) async {
    return (delete(notifications)
          ..where((t) => t.notificationType.equals(notificationType)))
        .go();
  }

  /// 既読かつ [threshold] より古い通知を物理削除する.
  ///
  /// 受信ボックスのデータ肥大化を防ぐためのクリーンアップ処理.
  /// 未読通知は削除されない（ユーザーが見逃した重要な情報を消さないため）.
  /// リマインダー等を含む全種別が対象.
  Future<int> deleteReadNotificationsOlderThan(DateTime threshold) {
    return (delete(notifications)
          ..where((t) => t.isRead.equals(true))
          ..where((t) => t.createdAt.isSmallerThanValue(threshold)))
        .go();
  }

  /// 指定種別の通知のうち、dedupKey が [keepKeys] に含まれない通知を削除する.
  ///
  /// announcements.json から削除されたエントリをユーザーの受信ボックスから
  /// 取り除くために使用する. 空の dedupKey を持つ通知（リマインダー等）は
  /// 影響を受けない.
  Future<int> deleteByTypeWhereDedupKeyNotIn(
    String notificationType,
    Set<String> keepKeys,
  ) async {
    final targets = await (select(notifications)
          ..where((t) => t.notificationType.equals(notificationType))
          ..where((t) => t.dedupKey.isNotValue('')))
        .get();
    var removed = 0;
    for (final n in targets) {
      if (!keepKeys.contains(n.dedupKey)) {
        await deleteById(n.id);
        removed++;
      }
    }
    return removed;
  }

  /// 同じ dedup_key を持つ重複通知を除去する（最古の1件のみ残す）.
  Future<int> removeDuplicates() async {
    final all = await getAll();
    final seen = <String>{};
    var removed = 0;
    // createdAt降順なので、新しい方が先に来る → 古い方（後から来る）を残す
    // 逆順にして古い方を先に処理
    for (final n in all.reversed) {
      if (n.dedupKey.isNotEmpty && seen.contains(n.dedupKey)) {
        await deleteById(n.id);
        removed++;
      } else {
        seen.add(n.dedupKey);
      }
    }
    return removed;
  }

  /// Notificationを削除する.
  Future<bool> deleteById(String notificationId) async {
    final count = await (delete(notifications)
          ..where((t) => t.id.equals(notificationId)))
        .go();
    return count > 0;
  }
}
